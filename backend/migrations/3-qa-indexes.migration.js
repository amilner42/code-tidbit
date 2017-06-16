/// 3rd migration file - Add indexes for optimizing retreiving QA objects for snipbits/bigbits. Additionally, go
/// through all snipbits/bigbits and initialize the default QA objects.

db.snipbitsQA.createIndex({ tidbitID: 1 });
db.bigbitsQA.createIndex({ tidbitID: 1 });

// Creates the default QAObject.
var defaultQAObject = function(tidbitID, tidbitAuthor) {
    return {
        tidbitID: tidbitID,
        tidbitAuthor: tidbitAuthor,
        questions: [],
        questionComments: [],
        answers: [],
        answerComments: []
    }
};

// Init QA objects for all snipbits.
db.snipbits.find().forEach((snipbit) => {
    db.snipbitsQA.insertOne(defaultQAObject(snipbit._id, snipbit.author));
});

// Init QA objects for all bigbits.
db.bigbits.find().forEach((bigbit) => {
    db.bigbitsQA.insertOne(defaultQAObject(bigbit._id, bigbit.author));
});
