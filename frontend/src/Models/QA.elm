module Models.QA exposing (..)

import Date
import DefaultServices.Editable as Editable
import DefaultServices.Sort as Sort
import Dict
import Elements.FileStructure as FS
import Models.Range as Range
import Models.Vote as Vote
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


{-| Currently both questions/answers are RateableContent, useful for sorting based on ratings.
-}
type alias RateableContent x =
    { x | pinned : Bool, upvotes : ( Bool, Int ), downvotes : ( Bool, Int ), createdAt : Date.Date }


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
    , newAnswers : Dict.Dict QuestionID NewAnswer
    , answerEdits : Dict.Dict AnswerID AnswerEdit
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


{-| A new answer being created.
-}
type alias NewAnswer =
    { answerText : AnswerText
    , previewMarkdown : Bool
    , showQuestion : Bool
    }


{-| An answer being edited.
-}
type alias AnswerEdit =
    { answerText : Editable.Editable AnswerText
    , previewMarkdown : Bool
    , showQuestion : Bool
    }


{-| Creates a `QuestionEdit` from a `Question`.
-}
questionEditFromQuestion : Question codePointer -> QuestionEdit codePointer
questionEditFromQuestion { questionText, codePointer } =
    { questionText = Editable.newEditing questionText
    , codePointer = Editable.newEditing codePointer
    , previewMarkdown = False
    }


{-| Creates an `AnswerEdit` from an `Answer` with default settings.
-}
answerEditFromAnswer : Answer -> AnswerEdit
answerEditFromAnswer { answerText } =
    { answerText = Editable.newEditing answerText
    , previewMarkdown = False
    , showQuestion = False
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


{-| Get's the newAnswer for the given snipbit/question if it exists.
-}
getNewAnswer : SnipbitID -> QuestionID -> QAState codePointer -> Maybe NewAnswer
getNewAnswer snipbitID questionID qaState =
    Dict.get snipbitID qaState
        |> Maybe.andThen (.newAnswers >> Dict.get questionID)


{-| Get's the answerEdit for the given snipbit/answerID if it exsits.
-}
getAnswerEdit : SnipbitID -> AnswerID -> QAState codePointer -> Maybe AnswerEdit
getAnswerEdit snipbitID answerID qaState =
    Dict.get snipbitID qaState
        |> Maybe.andThen (.answerEdits >> Dict.get answerID)


{-| Get's the browsing code pointer for a tidbit if it exsits.
-}
getBrowseCodePointer : TidbitID -> QAState codePointer -> Maybe codePointer
getBrowseCodePointer tidbitID qaState =
    Dict.get tidbitID qaState
        |> Maybe.andThen .browsingCodePointer


{-| BrowseCodePointer setter, handles setting default tidbitQAState if needed.
-}
setBrowsingCodePointer : SnipbitID -> Maybe codePointer -> QAState codePointer -> QAState codePointer
setBrowsingCodePointer snipbitID codePointer =
    setTidbitQAState snipbitID (\tidbitQAState -> { tidbitQAState | browsingCodePointer = codePointer })


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


{-| Updates a [published] question in the QA, handles all required logic:
  - Upvoting/downvoting question
  - Possibly removing previous upvote/downvote
  - Updating upvote/downvote count
  - Resorting questions.

NOTE: If `vote` is `Nothing`, means that the user was removing a vote (could be either upvote/downvote).
-}
rateQuestion : QuestionID -> Maybe Vote.Vote -> QA codePointer -> QA codePointer
rateQuestion questionID vote =
    let
        updateQuestionUpvotesAndDownvotesForQA qa =
            updateQuestion
                questionID
                (\question ->
                    { question
                        | upvotes =
                            case vote of
                                Just Vote.Upvote ->
                                    if Tuple.first question.upvotes then
                                        question.upvotes
                                    else
                                        ( True, (+) 1 <| Tuple.second question.upvotes )

                                _ ->
                                    if Tuple.first question.upvotes then
                                        ( False, (flip (-)) 1 <| Tuple.second question.upvotes )
                                    else
                                        question.upvotes
                        , downvotes =
                            case vote of
                                Just Vote.Downvote ->
                                    if Tuple.first question.downvotes then
                                        question.downvotes
                                    else
                                        ( True, (+) 1 <| Tuple.second question.downvotes )

                                _ ->
                                    if Tuple.first question.downvotes then
                                        ( False, (flip (-)) 1 <| Tuple.second question.downvotes )
                                    else
                                        question.downvotes
                    }
                )
                qa

        sortQuestionsForQA qa =
            { qa | questions = sortRateableContent qa.questions }
    in
        updateQuestionUpvotesAndDownvotesForQA >> sortQuestionsForQA


{-| Updates a [published] answer in the QA.
-}
updateAnswer : AnswerID -> (Answer -> Answer) -> QA codePointer -> QA codePointer
updateAnswer answerID answerUpdater qa =
    { qa
        | answers =
            List.map
                (\answer ->
                    if answer.id == answerID then
                        answerUpdater answer
                    else
                        answer
                )
                qa.answers
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
updateQuestionEdit :
    SnipbitID
    -> QuestionID
    -> (Maybe (QuestionEdit codePointer) -> Maybe (QuestionEdit codePointer))
    -> QAState codePointer
    -> QAState codePointer
updateQuestionEdit snipbitID questionID questionEditUpdater =
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


{-| newAnswer updater, handles setting default tidbitQAState if needed.

Updater has to handle case where no new answer exists yet for that question (hence `Maybe NewAnswer...`).
-}
updateNewAnswer :
    SnipbitID
    -> QuestionID
    -> (Maybe NewAnswer -> Maybe NewAnswer)
    -> QAState codePointer
    -> QAState codePointer
updateNewAnswer snipbitID questionID newAnswerUpdater =
    setTidbitQAState
        snipbitID
        (\tidbitQAState ->
            { tidbitQAState
                | newAnswers =
                    Dict.update
                        questionID
                        (\maybeNewAnswer -> newAnswerUpdater maybeNewAnswer)
                        tidbitQAState.newAnswers
            }
        )


{-| Sorts the RateableContent by:
    - is pinned
    - most upvotes
    - least downvotes
    - newest date
-}
sortRateableContent : List (RateableContent x) -> List (RateableContent x)
sortRateableContent =
    Sort.sortByAll
        [ Sort.createBoolComparator .pinned
        , Sort.reverseComparator <| Sort.createComparator (.upvotes >> Tuple.second)
        , Sort.createComparator (.downvotes >> Tuple.second)
        , Sort.reverseComparator <| Sort.createDateComparator .createdAt
        ]


{-| answerEdit updater, handles setting default tidbitQAState if needed.

Updater has to handle case where no new answer edit exists (hence `Maybe AnswerEdit...`).
-}
updateAnswerEdit :
    SnipbitID
    -> AnswerID
    -> (Maybe AnswerEdit -> Maybe AnswerEdit)
    -> QAState codePointer
    -> QAState codePointer
updateAnswerEdit snipbitID answerID answerEditUpdater =
    setTidbitQAState
        snipbitID
        (\tidbitQAState ->
            { tidbitQAState
                | answerEdits =
                    Dict.update
                        answerID
                        (\maybeAnswerEdit -> answerEditUpdater maybeAnswerEdit)
                        tidbitQAState.answerEdits
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


{-| A blank `NewAnswer`.
-}
defaultNewAnswer : NewAnswer
defaultNewAnswer =
    { answerText = "", showQuestion = True, previewMarkdown = False }
