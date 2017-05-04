/// 3rd migration file - Add indexes for optimizing retreiving QA objects for snipbits/bigbits.

db.snipbitsQA.createIndex({ tidbitID: 1 });
db.bigbitsQA.createIndex({ tidbitID: 1 });
