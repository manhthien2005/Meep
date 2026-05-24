# scripts/_helpers.ps1
# Shared config + helper functions, duoc dot-source boi create-module-issues.ps1

$repo         = "manhthien2005/Meep"
$projectNum   = 2
$projectOwner = "manhthien2005"

$ThienPDM = "manhthien2005"
$KhoaLND  = "CatS1mp"
$HanDHG   = "katheramp"
$NganTNK  = "JanaKimmm"

# Tao issue, tra ve issue number. Body ghi ra temp file tranh encoding issues voi --body
function New-Issue {
    param([string]$Title, [string]$Body, [string]$Assignee, [int]$Milestone = 0)
    $tmp = [System.IO.Path]::GetTempFileName()
    [System.IO.File]::WriteAllText($tmp, $Body, [System.Text.UTF8Encoding]::new())
    $ghArgs = @("issue", "create", "--repo", $repo,
        "--title", $Title, "--body-file", $tmp, "--assignee", $Assignee)
    $url = (& gh @ghArgs)
    Remove-Item $tmp -ErrorAction SilentlyContinue
    if ($null -eq $url -or $url -eq "") { return 0 }
    $url = $url.Trim()
    $num = [int](($url -split "/")[-1])
    if ($Milestone -gt 0) {
        & gh api "repos/$repo/issues/$num" -X PATCH -f "milestone=$Milestone" | Out-Null
    }
    & gh project item-add $projectNum --owner $projectOwner --url $url | Out-Null
    return $num
}

# Lay numeric ID (khac issue number) de link sub-issue
function Get-IssueId {
    param([int]$Num)
    $id = & gh api "repos/$repo/issues/$Num" --jq '.id' 2>$null
    return [long]$id
}

# Link sub-issue vao parent qua GitHub sub-issues API
function Add-SubIssue {
    param([int]$ParentNum, [long]$ChildId)
    & gh api "repos/$repo/issues/$ParentNum/sub_issues" -X POST -F "sub_issue_id=$ChildId" | Out-Null
}

# Tao parent issue + sub-issues, link tat ca vao parent
# Sub body ho tro placeholder {sub0},{sub1}... -> thay bang issue number thuc cua sub truoc do
function New-Module {
    param(
        [string]$ModuleTitle,
        [string]$ParentBody,
        [string]$Assignee,
        [int]$Milestone,
        [hashtable[]]$Subs
    )
    Write-Host "`n$ModuleTitle" -ForegroundColor Cyan

    $parentNum = New-Issue $ModuleTitle $ParentBody $Assignee $Milestone
    if ($parentNum -eq 0) {
        Write-Host "  ! Parent failed: $ModuleTitle" -ForegroundColor Red
        return
    }
    $parentId = Get-IssueId $parentNum
    Write-Host "  [Parent] #$parentNum" -ForegroundColor Yellow

    $subNums = @()
    foreach ($s in $Subs) {
        $body = $s.body
        for ($i = 0; $i -lt $subNums.Count; $i++) {
            $body = $body -replace "\{sub$i\}", "#$($subNums[$i])"
        }
        # Per-sub assignee override: neu sub co field 'assignee' thi dung, khong thi dung module-level
        $subAssignee = if ($s.ContainsKey('assignee') -and $s.assignee) { $s.assignee } else { $Assignee }
        $subNum = New-Issue $s.title $body $subAssignee $Milestone
        $subNums += $subNum
        if ($subNum -gt 0) {
            $subId = Get-IssueId $subNum
            Add-SubIssue $parentNum $subId
            Write-Host "    - #$subNum $($s.title)" -ForegroundColor White
        }
    }
}
