import {onDocumentDeleted} from "firebase-functions/v2/firestore";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";

// Initialize the Firebase Admin SDK
admin.initializeApp();

const db = admin.firestore();
const storage = admin.storage();

/**
 * Cloud Function to perform cleanup tasks when a document in the
 * 'publicContent' collection is deleted.
 */
export const onContentDeleted = onDocumentDeleted(
    "publicContent/{contentId}",
    async (event) => {
      const snap = event.data;
      if (!snap) {
        logger.log("No data associated with the event, skipping cleanup.");
        return;
      }

      const deletedData = snap.data();
      const contentId = event.params.contentId;
      const {authorId, contentType, imageUrl} = deletedData;

      logger.log(
          `Starting cleanup for contentId: ${contentId} by author: ${authorId}`,
      );

      const batch = db.batch();

      // 1. Delete image from Firebase Storage if it exists
      if (imageUrl) {
        try {
          // Create a reference from the HTTPS URL
          const fileRef = storage.bucket().file(new URL(imageUrl).pathname.split("/o/")[1]);
          await fileRef.delete();
          logger.log(`Deleted image: ${imageUrl}`);
        } catch (error) {
          logger.error(`Failed to delete image: ${imageUrl}`, error);
        }
      }

      // 2. Delete all comments in the subcollection
      const commentsRef = db.collection("publicContent").doc(contentId).collection("comments");
      const commentsSnapshot = await commentsRef.get();
      if (!commentsSnapshot.empty) {
        commentsSnapshot.docs.forEach((doc) => batch.delete(doc.ref));
        logger.log(`Deleting ${commentsSnapshot.size} comments.`);
      }

      // 3. If it's a book, delete it from all users' savedBooks and trackedBooks
      if (contentType === "Book") {
        const savedBooksQuery = db.collectionGroup("savedBooks").where("bookId", "==", contentId);
        const trackedBooksQuery = db.collectionGroup("trackedBooks").where("bookId", "==", contentId);

        const [savedSnapshot, trackedSnapshot] = await Promise.all([
          savedBooksQuery.get(),
          trackedBooksQuery.get(),
        ]);

        if (!savedSnapshot.empty) {
          savedSnapshot.docs.forEach((doc) => batch.delete(doc.ref));
          logger.log(`Deleting ${savedSnapshot.size} entries from savedBooks.`);
        }

        if (!trackedSnapshot.empty) {
          trackedSnapshot.docs.forEach((doc) => batch.delete(doc.ref));
          logger.log(`Deleting ${trackedSnapshot.size} entries from trackedBooks.`);
        }
      }

      // 4. Delete from the author's private content subcollection (if it exists)
      if (authorId) {
        const privateContentRef = db.collection("users").doc(authorId).collection("content").doc(contentId);
        batch.delete(privateContentRef);
        logger.log("Deleting entry from author's private content.");
      }

      // Commit all the batched delete operations
      try {
        await batch.commit();
        logger.log(`Successfully completed cleanup for contentId: ${contentId}`);
      } catch (error) {
        logger.error(`Error committing batch deletes for contentId: ${contentId}`, error);
      }
    });
