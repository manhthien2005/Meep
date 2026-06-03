package dev.meep.meep

import android.appwidget.AppWidgetManager
import android.content.Context
import android.graphics.Bitmap
import android.view.View
import android.widget.RemoteViews
import androidx.test.core.app.ApplicationProvider
import androidx.work.ListenableWorker
import androidx.work.testing.TestListenableWorkerBuilder
import com.bumptech.glide.Glide
import com.bumptech.glide.RequestBuilder
import com.bumptech.glide.RequestManager
import com.bumptech.glide.request.FutureTarget
import com.google.android.gms.tasks.Task
import com.google.android.gms.tasks.Tasks
import com.google.firebase.Timestamp
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.auth.FirebaseUser
import com.google.firebase.auth.GetTokenResult
import com.google.firebase.firestore.AggregateQuerySnapshot
import com.google.firebase.firestore.AggregateSource
import com.google.firebase.firestore.DocumentSnapshot
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.Query
import com.google.firebase.firestore.QuerySnapshot
import io.mockk.Runs
import io.mockk.every
import io.mockk.just
import io.mockk.mockk
import io.mockk.mockkConstructor
import io.mockk.mockkObject
import io.mockk.mockkStatic
import io.mockk.unmockkAll
import io.mockk.verify
import kotlinx.coroutines.test.runTest
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

/**
 * Unit tests cho [WidgetSyncWorker] — covers Task T6 acceptance criteria
 * (docs/plans/2026-05-23-widget-android.md §T6, issue #141):
 *
 *   1. Không có signed-in user → Result.success(), không crash.
 *   2. Có user → mock Firestore → widget được update với photo/avatar/
 *      caption/unread count đúng.
 *   3. Có user, authorAvatarUrl == null → default avatar drawable, không crash.
 *   4. Có user, count() query fail → unreadCount = 0, widget vẫn update.
 *
 * Note: spec text nhắc `MeepWidget.updateWidget()` nhưng implementation hiện
 * tại render trực tiếp trong [WidgetSyncWorker]; test verify cùng kết quả end
 * state qua [RemoteViews] calls + [AppWidgetManager.updateAppWidget].
 *
 * Robolectric SDK pinned tới 33 vì Robolectric 4.13 chỉ ship runtime tới
 * SDK 34 (app compileSdk có thể cao hơn theo Flutter SDK).
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [33])
class WidgetSyncWorkerTest {

    private lateinit var context: Context
    private lateinit var appWidgetManager: AppWidgetManager

    @Before
    fun setUp() {
        context = ApplicationProvider.getApplicationContext()

        mockkStatic(FirebaseAuth::class)
        mockkStatic(FirebaseFirestore::class)
        mockkStatic(AppWidgetManager::class)
        mockkStatic(Glide::class)
        mockkObject(WidgetDataStore)
        mockkObject(MeepWidget.Companion)
        mockkConstructor(RemoteViews::class)

        appWidgetManager = mockk(relaxed = true)
        every { AppWidgetManager.getInstance(any()) } returns appWidgetManager
        every { appWidgetManager.getAppWidgetIds(any()) } returns intArrayOf(WIDGET_ID)

        every { WidgetDataStore.readLastViewedAt(any()) } returns 0L
        every { MeepWidget.applyTapIntent(any(), any(), any()) } just Runs

        every { anyConstructed<RemoteViews>().setImageViewBitmap(any(), any()) } just Runs
        every { anyConstructed<RemoteViews>().setImageViewResource(any(), any()) } just Runs
        every { anyConstructed<RemoteViews>().setTextViewText(any(), any()) } just Runs
        every { anyConstructed<RemoteViews>().setViewVisibility(any(), any()) } just Runs
    }

    @After
    fun tearDown() {
        unmockkAll()
    }

    // ---------------------------------------------------------------------
    // Test 1 — No signed-in user
    // ---------------------------------------------------------------------

    @Test
    fun `no signed-in user returns success and renders placeholder`() = runTest {
        val auth = mockk<FirebaseAuth>(relaxed = true)
        every { FirebaseAuth.getInstance() } returns auth
        every { auth.currentUser } returns null

        val worker = buildWorker()
        val result = worker.doWork()

        assertTrue(result is ListenableWorker.Result.Success)
        assertEquals(ListenableWorker.Result.success(), result)

        // Placeholder visible, photo/avatar/caption/count hidden.
        verify { anyConstructed<RemoteViews>().setViewVisibility(R.id.widget_placeholder, View.VISIBLE) }
        verify { anyConstructed<RemoteViews>().setViewVisibility(R.id.widget_photo, View.GONE) }
        verify { anyConstructed<RemoteViews>().setViewVisibility(R.id.widget_avatar, View.GONE) }
        verify { anyConstructed<RemoteViews>().setViewVisibility(R.id.widget_caption, View.GONE) }
        verify { anyConstructed<RemoteViews>().setViewVisibility(R.id.widget_count, View.GONE) }

        // No Firestore access when signed-out.
        verify(exactly = 0) { FirebaseFirestore.getInstance() }
    }

    // ---------------------------------------------------------------------
    // Test 2 — Happy path
    // ---------------------------------------------------------------------

    @Test
    fun `happy path renders widget with photo avatar caption and unread count`() = runTest {
        givenSignedInUser(uid = USER_UID)
        val firestore = givenFirestoreReturnsPost(
            uid = USER_UID,
            postId = POST_ID,
            imageUrl = IMAGE_URL,
            authorAvatarUrl = AVATAR_URL,
            caption = CAPTION,
        )
        givenUnreadCount(firestore, uid = USER_UID, count = 5L)
        givenGlideBitmap()

        val worker = buildWorker()
        val result = worker.doWork()

        assertEquals(ListenableWorker.Result.success(), result)

        // Photo + avatar bitmap pushed.
        verify { anyConstructed<RemoteViews>().setImageViewBitmap(R.id.widget_photo, any()) }
        verify { anyConstructed<RemoteViews>().setImageViewBitmap(R.id.widget_avatar, any()) }
        verify { anyConstructed<RemoteViews>().setViewVisibility(R.id.widget_photo, View.VISIBLE) }
        verify { anyConstructed<RemoteViews>().setViewVisibility(R.id.widget_avatar, View.VISIBLE) }

        // Caption pill visible with exact text.
        verify { anyConstructed<RemoteViews>().setTextViewText(R.id.widget_caption, CAPTION) }
        verify { anyConstructed<RemoteViews>().setViewVisibility(R.id.widget_caption, View.VISIBLE) }

        // Unread badge "5" visible.
        verify { anyConstructed<RemoteViews>().setTextViewText(R.id.widget_count, "5") }
        verify { anyConstructed<RemoteViews>().setViewVisibility(R.id.widget_count, View.VISIBLE) }

        // Placeholder hidden.
        verify { anyConstructed<RemoteViews>().setViewVisibility(R.id.widget_placeholder, View.GONE) }

        // Widget pushed to AppWidgetManager.
        verify { appWidgetManager.updateAppWidget(WIDGET_ID, any<RemoteViews>()) }

        // Deep-link wired with postId.
        verify { MeepWidget.applyTapIntent(any(), any(), POST_ID) }
    }

    // ---------------------------------------------------------------------
    // Test 3 — Null avatar URL → default drawable
    // ---------------------------------------------------------------------

    @Test
    fun `null author avatar url falls back to default drawable without crash`() = runTest {
        givenSignedInUser(uid = USER_UID)
        val firestore = givenFirestoreReturnsPost(
            uid = USER_UID,
            postId = POST_ID,
            imageUrl = IMAGE_URL,
            authorAvatarUrl = null,
            caption = CAPTION,
        )
        givenUnreadCount(firestore, uid = USER_UID, count = 0L)
        givenGlideBitmap()

        val worker = buildWorker()
        val result = worker.doWork()

        assertEquals(ListenableWorker.Result.success(), result)

        // Photo pushed như bình thường.
        verify { anyConstructed<RemoteViews>().setImageViewBitmap(R.id.widget_photo, any()) }

        // Default avatar drawable resource used (KHÔNG bitmap).
        verify {
            anyConstructed<RemoteViews>().setImageViewResource(
                R.id.widget_avatar,
                R.drawable.widget_default_avatar,
            )
        }
        verify(exactly = 0) {
            anyConstructed<RemoteViews>().setImageViewBitmap(R.id.widget_avatar, any())
        }
        verify { anyConstructed<RemoteViews>().setViewVisibility(R.id.widget_avatar, View.VISIBLE) }

        // Count badge ẩn khi unread = 0.
        verify { anyConstructed<RemoteViews>().setViewVisibility(R.id.widget_count, View.GONE) }
    }

    // ---------------------------------------------------------------------
    // Test 4 — count() query failure → unread = 0, widget still updates
    // ---------------------------------------------------------------------

    @Test
    fun `count query failure defaults unread to zero and widget still updates`() = runTest {
        givenSignedInUser(uid = USER_UID)
        val firestore = givenFirestoreReturnsPost(
            uid = USER_UID,
            postId = POST_ID,
            imageUrl = IMAGE_URL,
            authorAvatarUrl = AVATAR_URL,
            caption = CAPTION,
        )
        givenUnreadCountFailure(firestore, uid = USER_UID)
        givenGlideBitmap()

        val worker = buildWorker()
        val result = worker.doWork()

        assertEquals(ListenableWorker.Result.success(), result)

        // Photo + avatar vẫn render.
        verify { anyConstructed<RemoteViews>().setImageViewBitmap(R.id.widget_photo, any()) }
        verify { anyConstructed<RemoteViews>().setImageViewBitmap(R.id.widget_avatar, any()) }
        verify { anyConstructed<RemoteViews>().setViewVisibility(R.id.widget_photo, View.VISIBLE) }

        // Count badge ẩn vì offline → 0.
        verify { anyConstructed<RemoteViews>().setViewVisibility(R.id.widget_count, View.GONE) }
        verify(exactly = 0) {
            anyConstructed<RemoteViews>().setTextViewText(R.id.widget_count, any<String>())
        }

        // Widget vẫn được push tới manager.
        verify { appWidgetManager.updateAppWidget(WIDGET_ID, any<RemoteViews>()) }
    }

    // ---------------------------------------------------------------------
    // Helpers
    // ---------------------------------------------------------------------

    private fun buildWorker(): WidgetSyncWorker =
        TestListenableWorkerBuilder<WidgetSyncWorker>(context).build()

    private fun givenSignedInUser(uid: String) {
        val auth = mockk<FirebaseAuth>(relaxed = true)
        val user = mockk<FirebaseUser>(relaxed = true)
        every { FirebaseAuth.getInstance() } returns auth
        every { auth.currentUser } returns user
        every { user.uid } returns uid

        // Token refresh succeeds (real Task chứ không mock — tránh extension fn mock pain).
        val tokenResult = mockk<GetTokenResult>(relaxed = true)
        every { user.getIdToken(false) } returns Tasks.forResult(tokenResult)
    }

    private fun givenFirestoreReturnsPost(
        uid: String,
        postId: String,
        imageUrl: String,
        authorAvatarUrl: String?,
        caption: String?,
    ): FirebaseFirestore {
        val firestore = mockk<FirebaseFirestore>(relaxed = true)
        every { FirebaseFirestore.getInstance() } returns firestore

        // Feed query → 1 doc with postId.
        val feedDoc = mockk<DocumentSnapshot>(relaxed = true)
        every { feedDoc.getString("postId") } returns postId
        every { feedDoc.id } returns "feed_doc_id"

        val feedSnap = mockk<QuerySnapshot>(relaxed = true)
        every { feedSnap.documents } returns listOf(feedDoc)

        every {
            firestore.collection("users")
                .document(uid)
                .collection("feed")
                .orderBy("createdAt", Query.Direction.DESCENDING)
                .limit(1)
                .get()
        } returns Tasks.forResult(feedSnap)

        // Post doc fetch.
        val postSnap = mockk<DocumentSnapshot>(relaxed = true)
        every { postSnap.exists() } returns true
        every { postSnap.id } returns postId
        every { postSnap.getString("imageUrl") } returns imageUrl
        every { postSnap.getString("backImageUrl") } returns null
        every { postSnap.getString("authorAvatarUrl") } returns authorAvatarUrl
        every { postSnap.getString("caption") } returns caption

        every {
            firestore.collection("posts").document(postId).get()
        } returns Tasks.forResult(postSnap)

        return firestore
    }

    private fun givenUnreadCount(firestore: FirebaseFirestore, uid: String, count: Long) {
        val aggregateSnap = mockk<AggregateQuerySnapshot>(relaxed = true)
        every { aggregateSnap.count } returns count

        every {
            firestore.collection("users")
                .document(uid)
                .collection("feed")
                .whereGreaterThan("createdAt", any<Timestamp>())
                .count()
                .get(AggregateSource.SERVER)
        } returns Tasks.forResult(aggregateSnap)
    }

    private fun givenUnreadCountFailure(firestore: FirebaseFirestore, uid: String) {
        every {
            firestore.collection("users")
                .document(uid)
                .collection("feed")
                .whereGreaterThan("createdAt", any<Timestamp>())
                .count()
                .get(AggregateSource.SERVER)
        } returns Tasks.forException(RuntimeException("simulated offline — count() failed"))
    }

    private fun givenGlideBitmap() {
        val bitmap = mockk<Bitmap>(relaxed = true)
        val futureTarget = mockk<FutureTarget<Bitmap>>(relaxed = true)
        every { futureTarget.get() } returns bitmap

        @Suppress("UNCHECKED_CAST")
        val requestBuilder = mockk<RequestBuilder<Bitmap>>(relaxed = true)
        every { requestBuilder.load(any<String>()) } returns requestBuilder
        every { requestBuilder.apply(any()) } returns requestBuilder
        every { requestBuilder.submit() } returns futureTarget

        val requestManager = mockk<RequestManager>(relaxed = true)
        every { requestManager.asBitmap() } returns requestBuilder

        every { Glide.with(any<Context>()) } returns requestManager
    }

    companion object {
        private const val WIDGET_ID = 42
        private const val USER_UID = "user_abc"
        private const val POST_ID = "post_123"
        private const val IMAGE_URL = "https://meep.dev/photo.jpg"
        private const val AVATAR_URL = "https://meep.dev/avatar.jpg"
        private const val CAPTION = "Hello Meep"
    }
}
