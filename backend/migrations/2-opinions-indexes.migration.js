/// 2nd migration file - Add indexes for optimizing queries for the opinion collection (hearts).

db.opinions.createIndex({ userID: 1 });
db.opinions.createIndex({ contentPointer: 1, rating: 1 });
