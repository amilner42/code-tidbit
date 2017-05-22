module Models.QA exposing (..)

import Date
import DefaultServices.Editable as Editable
import DefaultServices.InfixFunctions exposing (..)
import DefaultServices.Sort as Sort
import DefaultServices.Util as Util
import Dict
import Elements.Simple.FileStructure as FS
import List.Extra
import Models.Range as Range
import Models.Vote as Vote
import ProjectTypeAliases exposing (..)
import Set


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


{-| Comments should contain these fields.
-}
type alias Comment additional =
    { additional
        | id : String
        , questionID : String
        , commentText : String
        , authorID : String
        , authorEmail : String
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


{-| Anything that has upvotes and downvotes (allows for reusable functions).
-}
type alias ContentWithVotes x =
    { x | upvotes : ( Bool, Int ), downvotes : ( Bool, Int ) }


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
    , deletingComments : Set.Set CommentID
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
getQuestionByAnswerID : TidbitID -> AnswerID -> QA codePointer -> Maybe (Question codePointer)
getQuestionByAnswerID tidbitID answerID qa =
    getAnswerByID answerID qa.answers
        |> Maybe.map .questionID
        |> Maybe.andThen (\questionID -> getQuestionByID questionID qa.questions)


{-| Get's a questionEdit by the ID.
-}
getQuestionEditByID : TidbitID -> QuestionID -> QAState codePointer -> Maybe (QuestionEdit codePointer)
getQuestionEditByID tidbitID questionID qaState =
    Dict.get tidbitID qaState
        |> Maybe.andThen (.questionEdits >> Dict.get questionID)


{-| Get's the `newQuestion` for the given tidbitID.
-}
getNewQuestion : TidbitID -> QAState codePointer -> Maybe (NewQuestion codePointer)
getNewQuestion tidbitID qaState =
    Dict.get tidbitID qaState
        |> Maybe.map .newQuestion


{-| Get's the newAnswer for the given snipbit/question if it exists.
-}
getNewAnswer : TidbitID -> QuestionID -> QAState codePointer -> Maybe NewAnswer
getNewAnswer tidbitID questionID qaState =
    Dict.get tidbitID qaState
        |> Maybe.andThen (.newAnswers >> Dict.get questionID)


{-| Get's the answerEdit for the given snipbit/answerID if it exsits.
-}
getAnswerEdit : TidbitID -> AnswerID -> QAState codePointer -> Maybe AnswerEdit
getAnswerEdit tidbitID answerID qaState =
    Dict.get tidbitID qaState
        |> Maybe.andThen (.answerEdits >> Dict.get answerID)


{-| Get's the browsing code pointer for a tidbit if it exsits.
-}
getBrowseCodePointer : TidbitID -> QAState codePointer -> Maybe codePointer
getBrowseCodePointer tidbitID qaState =
    Dict.get tidbitID qaState
        |> Maybe.andThen .browsingCodePointer


{-| Get's the `questionCommentEdits` for a given tidbit from the `qaState` (or an empty dictionary).
-}
getQuestionCommentEdits : TidbitID -> QAState codePointer -> Dict.Dict CommentID (Editable.Editable CommentText)
getQuestionCommentEdits tidbitID qaState =
    Dict.get tidbitID qaState
        ||> .questionCommentEdits
        ?> Dict.empty


{-| Get's the `answerCommentEdits` for a given tidbit from the `qaState` (or an empty dictionary).
-}
getAnswerCommentEdits : TidbitID -> QAState codePointer -> Dict.Dict CommentID (Editable.Editable CommentText)
getAnswerCommentEdits tidbitID qaState =
    Dict.get tidbitID qaState
        ||> .answerCommentEdits
        ?> Dict.empty


{-| Get's the new question comment for a question if it exists, otherwise returns an empty string.
-}
getNewQuestionComment : TidbitID -> QuestionID -> QAState codePointer -> CommentText
getNewQuestionComment tidbitID questionID qaState =
    Dict.get tidbitID qaState
        ||> .newQuestionComments
        |||> Dict.get questionID
        ?> ""


{-| Get's all the `newAnswerComments` for a given tidbit (or an empty dictionary).
-}
getNewAnswerComments : TidbitID -> QAState codePointer -> Dict.Dict AnswerID CommentText
getNewAnswerComments tidbitID qaState =
    Dict.get tidbitID qaState
        ||> .newAnswerComments
        ?> Dict.empty


{-| Gets the `deletingComments` for a specific tidbit, defaults to an empty set if no tidbitQAState.
-}
getDeletingComments : TidbitID -> QAState codePointer -> Set.Set CommentID
getDeletingComments tidbitID qaState =
    Dict.get tidbitID qaState
        ||> .deletingComments
        ?> Set.empty


{-| Update the `deletingComments`, handles setting default tidbitQAState if needed.
-}
updateDeletingComments :
    TidbitID
    -> (Set.Set CommentID -> Set.Set CommentID)
    -> QAState codePointer
    -> QAState codePointer
updateDeletingComments tidbitID deletingCommentsUpdater =
    setTidbitQAState
        tidbitID
        (\tidbitQAState ->
            { tidbitQAState | deletingComments = deletingCommentsUpdater tidbitQAState.deletingComments }
        )


{-| BrowseCodePointer setter, handles setting default tidbitQAState if needed.
-}
setBrowsingCodePointer : TidbitID -> Maybe codePointer -> QAState codePointer -> QAState codePointer
setBrowsingCodePointer tidbitID codePointer =
    setTidbitQAState tidbitID (\tidbitQAState -> { tidbitQAState | browsingCodePointer = codePointer })


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
            updateQuestion questionID (updateVotes vote) qa
    in
        updateQuestionUpvotesAndDownvotesForQA >> sortQuestions


{-| Adds a `QuestionComment` to the [published] list of question comments.
-}
addQuestionComment : QuestionComment -> QA codePointer -> QA codePointer
addQuestionComment questionComment qa =
    { qa | questionComments = qa.questionComments ++ [ questionComment ] }


{-| Edits a [published] question comment.
-}
editQuestionComment : CommentID -> CommentText -> Date.Date -> QA codePointer -> QA codePointer
editQuestionComment commentID commentText lastModified qa =
    { qa
        | questionComments =
            List.Extra.updateIf
                (.id >> (==) commentID)
                (\comment -> { comment | commentText = commentText, lastModified = lastModified })
                qa.questionComments
    }


{-| Deletes a `QuestionComment` from the [published] list of question comments.
-}
deleteQuestionComment : CommentID -> QA codePointer -> QA codePointer
deleteQuestionComment commentID qa =
    { qa | questionComments = List.filter (.id >> (/=) commentID) qa.questionComments }


{-| Sorts the questions on a QA.
-}
sortQuestions : QA codePointer -> QA codePointer
sortQuestions qa =
    { qa | questions = sortRateableContent qa.questions }


{-| Updates a [published] answer, handles:
    - Upvoting/downvoting answer
    - Possibly removing previous upvote/downvote
    - Updating upvote/downvote count
    - Resorting answers.

NOTE: If vote is `Nothing`, means the user was was removing a vote (could be either upvote/downvote).
-}
rateAnswer : AnswerID -> Maybe Vote.Vote -> QA codePointer -> QA codePointer
rateAnswer answerID vote =
    let
        updateAnswerUpvotesAndDownvotesForQA qa =
            updateAnswer answerID (updateVotes vote) qa
    in
        updateAnswerUpvotesAndDownvotesForQA >> sortAnswers


{-| Adds a `AnswerComment` to the [published] list of answer comments.
-}
addAnswerComment : AnswerComment -> QA codePointer -> QA codePointer
addAnswerComment answerComment qa =
    { qa | answerComments = qa.answerComments ++ [ answerComment ] }


{-| Edits a [published] answer comment.
-}
editAnswerComment : CommentID -> CommentText -> Date.Date -> QA codePointer -> QA codePointer
editAnswerComment commentID commentText lastModified qa =
    { qa
        | answerComments =
            List.Extra.updateIf
                (.id >> (==) commentID)
                (\comment -> { comment | commentText = commentText, lastModified = lastModified })
                qa.answerComments
    }


{-| Deletes an `AnswerComment` from the [published] list of answer comments.
-}
deleteAnswerComment : CommentID -> QA codePointer -> QA codePointer
deleteAnswerComment commentID qa =
    { qa | answerComments = List.filter (.id >> (/=) commentID) qa.answerComments }


{-| Sorts the answers on a QA.
-}
sortAnswers : QA codePointer -> QA codePointer
sortAnswers qa =
    { qa | answers = sortRateableContent qa.answers }


{-| Updates a [published] question, handles:
    - Pinning/unpinning question
    - Resorting questions
-}
pinQuestion : QuestionID -> Bool -> QA codePointer -> QA codePointer
pinQuestion questionID isPinned =
    let
        updatePin =
            updateQuestion questionID (\question -> { question | pinned = isPinned })
    in
        updatePin >> sortQuestions


{-| Updates a [published] answer, handles:
    - Pinning/unpinning answer
    - Resorting answers
-}
pinAnswer : AnswerID -> Bool -> QA codePointer -> QA codePointer
pinAnswer answerID isPinned =
    let
        updatePin =
            updateAnswer answerID (\answer -> { answer | pinned = isPinned })
    in
        updatePin >> sortAnswers


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
    TidbitID
    -> (NewQuestion codePointer -> NewQuestion codePointer)
    -> QAState codePointer
    -> QAState codePointer
updateNewQuestion tidbitID newQuestionUpdater =
    setTidbitQAState tidbitID
        (\tidbitQAState -> { tidbitQAState | newQuestion = newQuestionUpdater tidbitQAState.newQuestion })


{-| questionEdit updater, handles setting default tidbitQAState if needed.

Updater has to handle case where no edit exits yet (hence `Maybe QuestionEdit...`).
-}
updateQuestionEdit :
    TidbitID
    -> QuestionID
    -> (Maybe (QuestionEdit codePointer) -> Maybe (QuestionEdit codePointer))
    -> QAState codePointer
    -> QAState codePointer
updateQuestionEdit tidbitID questionID questionEditUpdater =
    setTidbitQAState tidbitID
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
    TidbitID
    -> QuestionID
    -> (Maybe NewAnswer -> Maybe NewAnswer)
    -> QAState codePointer
    -> QAState codePointer
updateNewAnswer tidbitID questionID newAnswerUpdater =
    setTidbitQAState
        tidbitID
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
    TidbitID
    -> AnswerID
    -> (Maybe AnswerEdit -> Maybe AnswerEdit)
    -> QAState codePointer
    -> QAState codePointer
updateAnswerEdit tidbitID answerID answerEditUpdater =
    setTidbitQAState
        tidbitID
        (\tidbitQAState ->
            { tidbitQAState
                | answerEdits =
                    Dict.update
                        answerID
                        (\maybeAnswerEdit -> answerEditUpdater maybeAnswerEdit)
                        tidbitQAState.answerEdits
            }
        )


{-| Updates the `questionCommentEdits` on a `qaState`, handles setting default if no `tidbitQAState` exists.
-}
updateQuestionCommentEdits :
    TidbitID
    -> (Dict.Dict CommentID (Editable.Editable CommentText) -> Dict.Dict CommentID (Editable.Editable CommentText))
    -> QAState codePointer
    -> QAState codePointer
updateQuestionCommentEdits tidbitID questionCommentEditsUpdater =
    setTidbitQAState
        tidbitID
        (\tidbitQAState ->
            { tidbitQAState
                | questionCommentEdits = questionCommentEditsUpdater tidbitQAState.questionCommentEdits
            }
        )


{-| Updates the `answerCommentEdits` on a `qaState`, handles setting default if no `tidbitQAState` exists.
-}
updateAnswerCommentEdits :
    TidbitID
    -> (Dict.Dict CommentID (Editable.Editable CommentText) -> Dict.Dict CommentID (Editable.Editable CommentText))
    -> QAState codePointer
    -> QAState codePointer
updateAnswerCommentEdits tidbitID answerCommentEditsUpdater =
    setTidbitQAState
        tidbitID
        (\tidbitQAState ->
            { tidbitQAState
                | answerCommentEdits = answerCommentEditsUpdater tidbitQAState.answerCommentEdits
            }
        )


{-| Updates the `newAnswerComments` on a `qaState`, handles setting default if not `tidbitQAState` exists.
-}
updateNewAnswerComments :
    TidbitID
    -> (Dict.Dict AnswerID CommentText -> Dict.Dict AnswerID CommentText)
    -> QAState codePointer
    -> QAState codePointer
updateNewAnswerComments tidbitID newAnswerCommentsUpdater =
    setTidbitQAState
        tidbitID
        (\tidbitQAState ->
            { tidbitQAState | newAnswerComments = newAnswerCommentsUpdater tidbitQAState.newAnswerComments }
        )


{-| Set's a single `newQuestionComment`, handles setting default if no `tidbitQAState` exists.

If you'd like to delete the new question comment, pass in `Nothing` for the `commentText`.
-}
setNewQuestionComment : TidbitID -> QuestionID -> Maybe CommentText -> QAState codePointer -> QAState codePointer
setNewQuestionComment tidbitID questionID commentText =
    setTidbitQAState
        tidbitID
        (\tidbitQAState ->
            { tidbitQAState
                | newQuestionComments = Dict.update questionID (always commentText) tidbitQAState.newQuestionComments
            }
        )


{-| Helper for creating setters which automatically handle the `tidbitQAState` being missing (use default).
-}
setTidbitQAState :
    TidbitID
    -> (TidbitQAState codePointer -> TidbitQAState codePointer)
    -> QAState codePointer
    -> QAState codePointer
setTidbitQAState tidbitID tidbitQAStateUpdater qaState =
    Dict.update
        tidbitID
        (\maybeTidbitQAState ->
            Just <|
                case maybeTidbitQAState of
                    Nothing ->
                        tidbitQAStateUpdater defaultTidbitQAState

                    Just tidbitQAState ->
                        tidbitQAStateUpdater tidbitQAState
        )
        qaState


{-| Helper for updating the vote count.

NOTE: If `vote` is `Nothing` that means that the user was removing his vote.
-}
updateVotes : Maybe Vote.Vote -> ContentWithVotes x -> ContentWithVotes x
updateVotes vote contentWithVotes =
    { contentWithVotes
        | upvotes =
            case vote of
                Just Vote.Upvote ->
                    if Tuple.first contentWithVotes.upvotes then
                        contentWithVotes.upvotes
                    else
                        ( True, (+) 1 <| Tuple.second contentWithVotes.upvotes )

                _ ->
                    if Tuple.first contentWithVotes.upvotes then
                        ( False, (flip (-)) 1 <| Tuple.second contentWithVotes.upvotes )
                    else
                        contentWithVotes.upvotes
        , downvotes =
            case vote of
                Just Vote.Downvote ->
                    if Tuple.first contentWithVotes.downvotes then
                        contentWithVotes.downvotes
                    else
                        ( True, (+) 1 <| Tuple.second contentWithVotes.downvotes )

                _ ->
                    if Tuple.first contentWithVotes.downvotes then
                        ( False, (flip (-)) 1 <| Tuple.second contentWithVotes.downvotes )
                    else
                        contentWithVotes.downvotes
    }


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
    , deletingComments = Set.empty
    }


{-| A blank `NewAnswer`.
-}
defaultNewAnswer : NewAnswer
defaultNewAnswer =
    { answerText = "", showQuestion = True, previewMarkdown = False }


{-| A defualt `NewQuestion`.
-}
defaultNewQuestion : NewQuestion codePointer
defaultNewQuestion =
    { codePointer = Nothing, questionText = "", previewMarkdown = False }
