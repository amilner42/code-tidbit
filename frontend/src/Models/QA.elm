module Models.QA exposing (..)

import Date
import DefaultServices.Editable as Editable
import Dict
import Elements.FileStructure as FS
import Models.Range as Range
import ProjectTypeAliases exposing (..)


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
    , answers : List Answer
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


{-| The user's QA states for all the tidbits.

For keeping track of things like half-written questions, or new questions etc...

NOTE: The state for each tidbit is saved separately so tidbit-states do not overwrite each other.
-}
type alias QAState codePointer =
    Dict.Dict TidbitID (TidbitQAState codePointer)


{-| The QAState for snipbits.
-}
type alias SnipbitQAState =
    QAState Range.Range


{-| The QA state for a single tidbit.

State includes creating new and editing: question / answers on questions / comment on answers / comment on questions.
-}
type alias TidbitQAState codePointer =
    { browsingCodePointer : Maybe codePointer
    , newQuestion : NewQuestion codePointer
    , questionEdits : Dict.Dict QuestionID (QuestionEdit codePointer)
    , newAnswers : Dict.Dict QuestionID AnswerText
    , answerEdits : Dict.Dict AnswerID (Editable.Editable String)
    , newQuestionComments : Dict.Dict QuestionID CommentText
    , newAnswerComments : Dict.Dict AnswerID CommentText
    , questionCommentEdits : Dict.Dict CommentID (Editable.Editable CommentText)
    , answerCommentEdits : Dict.Dict CommentID (Editable.Editable CommentText)
    }


{-| A question being edited.
-}
type alias QuestionEdit codePointer =
    { questionText : Editable.Editable QuestionText
    , codePointer : Editable.Editable codePointer
    , previewMarkdown : Bool
    }


{-| A new question being created.
-}
type alias NewQuestion codePointer =
    { questionText : QuestionText
    , codePointer : Maybe codePointer
    , previewMarkdown : Bool
    }


{-| Creates a `QuestionEdit` from a `Question`.
-}
questionEditFromQuestion : Question codePointer -> QuestionEdit codePointer
questionEditFromQuestion { questionText, codePointer } =
    { questionText = Editable.newEditing questionText
    , codePointer = Editable.newEditing codePointer
    , previewMarkdown = False
    }


{-| Get's a question by the ID.
-}
getQuestionByID : QuestionID -> List (Question codePointer) -> Maybe (Question codePointer)
getQuestionByID questionID questions =
    List.filter (\{ id } -> id == questionID) questions
        |> List.head


{-| Get's an answer by the ID.
-}
getAnswerByID : AnswerID -> List Answer -> Maybe Answer
getAnswerByID answerID answers =
    List.filter (\{ id } -> id == answerID) answers
        |> List.head


{-| Get's a question for a given answer.
-}
getQuestionByAnswerID : SnipbitID -> AnswerID -> QA codePointer -> Maybe (Question codePointer)
getQuestionByAnswerID snipbitID answerID qa =
    getAnswerByID answerID qa.answers
        |> Maybe.map .questionID
        |> Maybe.andThen (\questionID -> getQuestionByID questionID qa.questions)


{-| Get's a questionEdit by the ID.
-}
getQuestionEditByID : SnipbitID -> QuestionID -> QAState codePointer -> Maybe (QuestionEdit codePointer)
getQuestionEditByID snipbitID questionID qaState =
    Dict.get snipbitID qaState
        |> Maybe.andThen (.questionEdits >> Dict.get questionID)


{-| Get's the `newQuestion` for the given snipbitID.
-}
getNewQuestion : SnipbitID -> QAState codePointer -> Maybe (NewQuestion codePointer)
getNewQuestion snipbitID qaState =
    Dict.get snipbitID qaState
        |> Maybe.map .newQuestion


{-| BrowseCodePointer setter, handles setting default tidbitQAState if needed.
-}
setBrowsingCodePointer : SnipbitID -> codePointer -> QAState codePointer -> QAState codePointer
setBrowsingCodePointer snipbitID codePointer =
    setTidbitQAState snipbitID (\tidbitQAState -> { tidbitQAState | browsingCodePointer = Just codePointer })


{-| Updates a [published] question in the QA.
-}
updateQuestion : QuestionID -> (Question codePointer -> Question codePointer) -> QA codePointer -> QA codePointer
updateQuestion questionID questionUpdater qa =
    { qa
        | questions =
            List.map
                (\question ->
                    if question.id == questionID then
                        questionUpdater question
                    else
                        question
                )
                qa.questions
    }


{-| NewQuestion updater, handles setting default tidbitQAState if needed.
-}
updateNewQuestion :
    SnipbitID
    -> (NewQuestion codePointer -> NewQuestion codePointer)
    -> QAState codePointer
    -> QAState codePointer
updateNewQuestion snipbitID newQuestionUpdater =
    setTidbitQAState snipbitID
        (\tidbitQAState -> { tidbitQAState | newQuestion = newQuestionUpdater tidbitQAState.newQuestion })


{-| questionEdit updater, handles setting default tidbitQAState if needed.

Updater has to handle case where no edit exits yet (hence `Maybe QuestionEdit...`).
-}
updateEditQuestion :
    SnipbitID
    -> QuestionID
    -> (Maybe (QuestionEdit codePointer) -> Maybe (QuestionEdit codePointer))
    -> QAState codePointer
    -> QAState codePointer
updateEditQuestion snipbitID questionID questionEditUpdater =
    setTidbitQAState snipbitID
        (\tidbitQAState ->
            { tidbitQAState
                | questionEdits =
                    Dict.update
                        questionID
                        (\maybeQuestionEdit -> questionEditUpdater maybeQuestionEdit)
                        tidbitQAState.questionEdits
            }
        )


{-| Helper for creating setters which automatically handle the `tidbitQAState` being missing (use default).
-}
setTidbitQAState :
    SnipbitID
    -> (TidbitQAState codePointer -> TidbitQAState codePointer)
    -> QAState codePointer
    -> QAState codePointer
setTidbitQAState snipbitID tidbitQAStateUpdater qaState =
    Dict.update
        snipbitID
        (\maybeTidbitQAState ->
            Just <|
                case maybeTidbitQAState of
                    Nothing ->
                        tidbitQAStateUpdater defaultTidbitQAState

                    Just tidbitQAState ->
                        tidbitQAStateUpdater tidbitQAState
        )
        qaState


{-| The default state for `TidbitQAState`.
-}
defaultTidbitQAState : TidbitQAState codePointer
defaultTidbitQAState =
    { browsingCodePointer = Nothing
    , newQuestion = { questionText = "", codePointer = Nothing, previewMarkdown = False }
    , questionEdits = Dict.empty
    , newAnswers = Dict.empty
    , answerEdits = Dict.empty
    , newQuestionComments = Dict.empty
    , newAnswerComments = Dict.empty
    , questionCommentEdits = Dict.empty
    , answerCommentEdits = Dict.empty
    }
