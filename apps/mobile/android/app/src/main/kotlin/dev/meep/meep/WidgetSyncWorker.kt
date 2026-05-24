package dev.meep.meep

import android.content.Context
import androidx.work.Worker
import androidx.work.WorkerParameters

// TODO(W/T2/TBD): implement WidgetSyncWorker
// (1) Get Firebase ID token — FirebaseAuth.currentUser?.getIdToken(false)?.await()
// (2) Query /users/{uid}/feed LIMIT 1 → fetch /posts/{postId}
// (3) Download image with Glide → cache to internal storage
// (4) Update widget via AppWidgetManager
class WidgetSyncWorker(
    context: Context,
    params: WorkerParameters,
) : Worker(context, params) {
    override fun doWork(): Result = Result.success()
}
