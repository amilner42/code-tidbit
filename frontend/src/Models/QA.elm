module Models.QA exposing (..)

import Date
import Elements.FileStructure as FS
import Models.Range as Range


{-| The QA for snipbits.
-}
type alias SnipbitQA =
    QA Range.Range


{-| The QA for bigbits.
-}
type alias BigbitQA =
    QA BigbitCodePointer


{-| A QA document, almost directly a copy of the database version.
-}
type alias QA codePointerType =
    { id : String
    , tidbitID : String
    , tidbitAuthor : String
    , questions : List (Question codePointerType)
    , questionComments : List QuestionComment
    , answer : List Answer
    , answerComments : List AnswerComment
    }


{-| Snipbits use `Range`s as their code pointers.
-}
type alias SnipbitQuestion =
    Question Range.Range


{-| Bigbits use `BigbitCodePointer` as their code pointers.
-}
type alias BigbitQuestion =
    Question BigbitCodePointer


{-| A single question referring to some code.
-}
type alias Question codePointerType =
    { id : String
    , questionText : String
    , authorID : String
    , authorEmail : String
    , codePointer : codePointerType
    , upvotes : ( Bool, Int )
    , downvotes : ( Bool, Int )
    , pinned : Bool
    , lastModified : Date.Date
    , createdAt : Date.Date
    }


{-| An answer to a specific question.
-}
type alias Answer =
    { id : String
    , questionID : String
    , answerText : String
    , authorID : String
    , authorEmail : String
    , upvotes : ( Bool, Int )
    , downvotes : ( Bool, Int )
    , pinned : Bool
    , lastModified : Date.Date
    , createdAt : Date.Date
    }


{-| A comment made on a question.
-}
type alias QuestionComment =
    { id : String
    , questionID : String
    , commentText : String
    , authorID : String
    , authorEmail : String
    , lastModified : Date.Date
    , createdAt : Date.Date
    }


{-| A comment made on an answer.
-}
type alias AnswerComment =
    { id : String
    , questionID : String
    , commentText : String
    , authorID : String
    , authorEmail : String
    , lastModified : Date.Date
    , createdAt : Date.Date
    , answerID : String
    }


{-| Bigbit codePointers need to include the file and range.
-}
type alias BigbitCodePointer =
    { file : FS.Path, range : Range.Range }
