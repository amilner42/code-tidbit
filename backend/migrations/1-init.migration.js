/// 1st migration file - Initilize a bunch of indexes for our initial data models.

// Initial Regular Indexes

db.completed.createIndex({ user: 1, tidbitPointer: 1});
db.snipbits.createIndex({ author: 1 });
db.snipbits.createIndex({ lastModified: 1 });
db.snipbits.createIndex({ language: 1 });
db.bigbits.createIndex({ author: 1 });
db.bigbits.createIndex({ lastModified: 1});
db.bigbits.createIndex({ languages: 1 });
db.stories.createIndex({ author: 1 });
db.stories.createIndex({ lastModified: 1 });
db.stories.createIndex({ languages: 1 });
db.users.createIndex({ email: 1 });

// Initial Text indexes

const textIndex = { name: "text", description: "text", tags: "text" };
// Because we already have a field named `language` that isn't for specifying the index language, so we have to tell
// mongo to use a different field for the language_override property.
const additionalSettings = { language_override: "dummy" };

db.snipbits.createIndex(textIndex, additionalSettings);
db.bigbits.createIndex(textIndex, additionalSettings);
db.stories.createIndex(textIndex, additionalSettings)
