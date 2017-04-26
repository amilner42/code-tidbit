/// 2nd migration file.

db.opinions.createIndex({ userID: 1 });
db.opinions.createIndex({ contentPointer: 1, rating: 1 });
