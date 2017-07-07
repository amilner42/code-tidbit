/// 3rd migration file - Add indexes for optimizing retreiving notifications for a user / hash. Additionally I change
// the compound index on the completed collection so that it can be used for counting completed regardless of user.

db.notifications.createIndex({ hash: 1 });
db.notifications.createIndex({ userID: 1, createdAt: -1 });

// Drop current compound index.
db.completed.dropIndex("user_1_tidbitPointer_1");
// Create new compound index in reverse order. This allows us to count based on tidbitPointer alone, while still
// supporting the previous queries. The one downside is in the future if we want to go all the `completed` for a user
// we will not be able to use this index, in that case, we should just have them be two seperate indexes. But in the
// meantime a compound index does the job and takes less space.
db.completed.createIndex({ tidbitPointer: 1, user: 1 });
