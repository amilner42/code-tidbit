module Elements.Complex.ViewQuestion exposing (..)

import DefaultServices.Editable as Editable
import DefaultServices.InfixFunctions exposing (..)
import DefaultServices.Util as Util
import Dict
import Elements.Complex.CommentList as CommentList
import Elements.Simple.Markdown as Markdown
import Html exposing (Html, div, span, text, button, i)
import Html.Attributes exposing (class, classList)
import Html.Events exposing (onClick)
import Models.QA exposing (..)
import ProjectTypeAliases exposing (..)
import Set


type Msg
    = QuestionCommentListMsg CommentList.Msg
    | AnswerCommentListMsg AnswerID CommentList.Msg
    | AddToDeletingAnswers AnswerID


type alias Model =
    { questionCommentEdits : Dict.Dict CommentID (Editable.Editable CommentText)
    , newQuestionComment : CommentText
    , answerCommentEdits : Dict.Dict CommentID (Editable.Editable CommentText)
    , newAnswerComments : Dict.Dict AnswerID CommentText
    , deletingComments : Set.Set CommentID
    , deletingAnswers : Set.Set AnswerID
    }


type alias RenderConfig msg codePointer =
    { msgTagger : Msg -> msg
    , userID : Maybe UserID
    , tidbitAuthorID : UserID
    , tab : Tab
    , question : Question codePointer
    , answers : List Answer
    , questionComments : List QuestionComment
    , answerComments : List AnswerComment
    , goToBrowseAllQuestions : msg
    , goToQuestionTab : msg
    , goToAnswersTab : msg
    , goToQuestionCommentsTab : msg
    , goToAnswerTab : Answer -> msg
    , goToAnswerCommentsTab : Answer -> msg
    , goToQuestionComment : QuestionComment -> msg
    , goToAnswerComment : AnswerComment -> msg
    , goToAnswerQuestion : msg
    , goToEditQuestion : msg
    , goToEditAnswer : Answer -> msg
    , deleteAnswer : Answer -> msg
    , upvoteQuestion : msg
    , removeUpvoteQuestion : msg
    , downvoteQuestion : msg
    , removeDownvoteQuestion : msg
    , upvoteAnswer : Answer -> msg
    , removeUpvoteAnswer : Answer -> msg
    , downvoteAnswer : Answer -> msg
    , removeDownvoteAnswer : Answer -> msg
    , pinQuestion : msg
    , unpinQuestion : msg
    , pinAnswer : Answer -> msg
    , unpinAnswer : Answer -> msg
    , commentOnQuestion : CommentText -> msg
    , commentOnAnswer : AnswerID -> CommentText -> msg
    , deleteQuestionComment : CommentID -> msg
    , deleteAnswerComment : CommentID -> msg
    , editQuestionComment : CommentID -> CommentText -> msg
    , editAnswerComment : CommentID -> CommentText -> msg
    , handleUnauthAction : String -> msg
    }


view : RenderConfig msg codePointer -> Model -> Html msg
view config model =
    let
        extendedTopBar isAnswerTab answer =
            div
                [ class "extended-top-bar" ]
                [ div
                    [ classList
                        [ ( "tab left-tab", True )
                        , ( "selected", isAnswerTab )
                        ]
                    , onClick (config.goToAnswerTab answer)
                    ]
                    [ text "ANSWER" ]
                , div
                    [ classList
                        [ ( "tab right-tab", True )
                        , ( "selected", not isAnswerTab )
                        ]
                    , onClick (config.goToAnswerCommentsTab answer)
                    ]
                    [ text "COMMENTS" ]
                ]

        unauthMessageForUpvoteAndDownvote =
            "We want your feedback, sign up for free and get access to all of CodeTidbit in seconds!"
    in
        div [ class "view-question" ] <|
            [ div
                [ class "link qa-top-right-link"
                , onClick config.goToBrowseAllQuestions
                ]
                [ text "see all questions" ]
            , div
                [ class "top-bar" ]
                [ div
                    [ classList
                        [ ( "tab", True )
                        , ( "selected", config.tab == QuestionTab )
                        ]
                    , onClick config.goToQuestionTab
                    ]
                    [ text "QUESTION" ]
                , div
                    [ classList
                        [ ( "tab center-tab", True )
                        , ( "selected", isQuestionCommentsTab config.tab )
                        ]
                    , onClick config.goToQuestionCommentsTab
                    ]
                    [ text "COMMENTS" ]
                , div
                    [ classList
                        [ ( "tab", True )
                        , ( "selected", (==) AnswersTab config.tab )
                        ]
                    , onClick config.goToAnswersTab
                    ]
                    [ text "ANSWERS" ]
                ]
            , case config.tab of
                QuestionTab ->
                    div
                        [ class "question-tab" ]
                        [ Markdown.view [ class "question-markdown" ] config.question.questionText
                        , reactiveRatingsBottomBarView
                            { upvotes = config.question.upvotes
                            , downvotes = config.question.downvotes
                            , isPinned = config.question.pinned
                            , isAuthor = config.userID == (Just config.question.authorID)
                            , isTidbitAuthor = config.userID == (Just config.tidbitAuthorID)
                            , isDeleteAlreadyClicked = False
                            , upvote =
                                case config.userID of
                                    Just _ ->
                                        config.upvoteQuestion

                                    Nothing ->
                                        config.handleUnauthAction unauthMessageForUpvoteAndDownvote
                            , removeUpvote = config.removeUpvoteQuestion
                            , downvote =
                                case config.userID of
                                    Just _ ->
                                        config.downvoteQuestion

                                    Nothing ->
                                        config.handleUnauthAction unauthMessageForUpvoteAndDownvote
                            , removeDownvote = config.removeDownvoteQuestion
                            , pin = config.pinQuestion
                            , unpin = config.unpinQuestion
                            , edit = config.goToEditQuestion
                            , delete = Nothing
                            }
                        ]

                QuestionCommentsTab maybeCommentID ->
                    CommentList.view
                        { msgTagger = config.msgTagger << QuestionCommentListMsg
                        , userID = config.userID
                        , comments = config.questionComments
                        , isSmall = False
                        , goToComment = config.goToQuestionComment
                        , newComment = config.commentOnQuestion
                        , editComment = config.editQuestionComment
                        , deleteComment = config.deleteQuestionComment
                        }
                        { commentEdits = model.questionCommentEdits
                        , newCommentText = model.newQuestionComment
                        , deletingComments = model.deletingComments
                        }

                AnswersTab ->
                    div
                        [ class "answers-tab" ]
                        [ div
                            [ class "answers-box" ]
                            [ if List.isEmpty config.answers then
                                div [ class "no-answers-text" ] [ text "Be the first to answer the question" ]
                              else
                                div [ class "answers" ] <|
                                    List.map (answerBoxView config.goToAnswerTab) config.answers
                            ]
                        , div
                            [ class "answer-question"
                            , onClick config.goToAnswerQuestion
                            ]
                            [ text "Answer Question" ]
                        ]

                AnswerTab answerID ->
                    case getAnswerByID answerID config.answers of
                        Just answer ->
                            div
                                [ class "answer-tab" ]
                                [ extendedTopBar True answer
                                , Markdown.view [ class "answer-markdown" ] answer.answerText
                                , reactiveRatingsBottomBarView
                                    { upvotes = answer.upvotes
                                    , downvotes = answer.downvotes
                                    , isPinned = answer.pinned
                                    , isAuthor = config.userID == (Just answer.authorID)
                                    , isTidbitAuthor = config.userID == (Just config.tidbitAuthorID)
                                    , isDeleteAlreadyClicked = Set.member answer.id model.deletingAnswers
                                    , upvote =
                                        case config.userID of
                                            Just _ ->
                                                config.upvoteAnswer answer

                                            Nothing ->
                                                config.handleUnauthAction unauthMessageForUpvoteAndDownvote
                                    , removeUpvote = config.removeUpvoteAnswer answer
                                    , downvote =
                                        case config.userID of
                                            Just _ ->
                                                config.downvoteAnswer answer

                                            Nothing ->
                                                config.handleUnauthAction unauthMessageForUpvoteAndDownvote
                                    , removeDownvote = config.removeDownvoteAnswer answer
                                    , pin = config.pinAnswer answer
                                    , unpin = config.unpinAnswer answer
                                    , edit = config.goToEditAnswer answer
                                    , delete =
                                        if Set.member answer.id model.deletingAnswers then
                                            Just <| config.deleteAnswer answer
                                        else
                                            Just <| config.msgTagger <| AddToDeletingAnswers answer.id
                                    }
                                ]

                        Nothing ->
                            Util.hiddenDiv

                AnswerCommentsTab answerID maybeCommentID ->
                    case getAnswerByID answerID config.answers of
                        Just answer ->
                            div
                                [ class "answer-comments-tab" ]
                                [ extendedTopBar False answer
                                , CommentList.view
                                    { msgTagger = config.msgTagger << (AnswerCommentListMsg answerID)
                                    , userID = config.userID
                                    , comments = List.filter (.answerID >> (==) answerID) config.answerComments
                                    , isSmall = True
                                    , goToComment = config.goToAnswerComment
                                    , newComment = config.commentOnAnswer answer.id
                                    , editComment = config.editAnswerComment
                                    , deleteComment = config.deleteAnswerComment
                                    }
                                    { commentEdits = model.answerCommentEdits
                                    , newCommentText = "" <? Dict.get answerID model.newAnswerComments
                                    , deletingComments = model.deletingComments
                                    }
                                ]

                        Nothing ->
                            Util.hiddenDiv
            ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        QuestionCommentListMsg commentListMsg ->
            let
                commentListModel =
                    { commentEdits = model.questionCommentEdits
                    , newCommentText = model.newQuestionComment
                    , deletingComments = model.deletingComments
                    }

                ( newCommentListModel, newCommentListMsg ) =
                    CommentList.update commentListMsg commentListModel
            in
                ( { model
                    | questionCommentEdits = newCommentListModel.commentEdits
                    , newQuestionComment = newCommentListModel.newCommentText
                    , deletingComments = newCommentListModel.deletingComments
                  }
                , Cmd.map QuestionCommentListMsg newCommentListMsg
                )

        AnswerCommentListMsg answerID commentListMsg ->
            let
                commentListModel =
                    { commentEdits = model.answerCommentEdits
                    , newCommentText = "" <? Dict.get answerID model.newAnswerComments
                    , deletingComments = model.deletingComments
                    }

                ( newCommentListModel, newCommentListMsg ) =
                    CommentList.update commentListMsg commentListModel
            in
                ( { model
                    | answerCommentEdits = newCommentListModel.commentEdits
                    , newAnswerComments =
                        Dict.insert answerID newCommentListModel.newCommentText model.newAnswerComments
                    , deletingComments = newCommentListModel.deletingComments
                  }
                , Cmd.map (AnswerCommentListMsg answerID) newCommentListMsg
                )

        AddToDeletingAnswers answerID ->
            ( { model | deletingAnswers = Set.insert answerID model.deletingAnswers }, Cmd.none )


answerBoxView : (Answer -> msg) -> Answer -> Html msg
answerBoxView goToAnswer answer =
    div
        [ class "answer-box"
        , onClick <| goToAnswer answer
        ]
        [ div [ class "answer-text" ] [ text <| answer.answerText ]
        , div
            [ class "bottom-bar" ]
            [ div [ class "email" ] [ text <| answer.authorEmail ]
            , span [ class "dislike-count" ] [ text <| toString <| Tuple.second <| answer.downvotes ]
            , i [ class "material-icons dislike" ] [ text "thumb_down" ]
            , span [ class "like-count" ] [ text <| toString <| Tuple.second <| answer.upvotes ]
            , i [ class "material-icons like" ] [ text "thumb_up" ]
            , i
                [ classList
                    [ ( "material-icons pinned", True )
                    , ( "hidden", not answer.pinned )
                    ]
                ]
                [ text "star" ]
            ]
        ]


type alias ReactiveRatingsBottomBarRenderConfig msg =
    { upvotes : ( Bool, Int )
    , downvotes : ( Bool, Int )
    , isPinned : Bool
    , isAuthor : Bool
    , isTidbitAuthor : Bool
    , isDeleteAlreadyClicked : Bool
    , upvote : msg
    , removeUpvote : msg
    , downvote : msg
    , removeDownvote : msg
    , pin : msg
    , unpin : msg
    , edit : msg
    , delete : Maybe msg
    }


{-| The bottom bar with the upvotes/downvotes and attached click handlers for upvoting/downvoting.
-}
reactiveRatingsBottomBarView : ReactiveRatingsBottomBarRenderConfig msg -> Html msg
reactiveRatingsBottomBarView config =
    let
        upvotedQuestion =
            Tuple.first config.upvotes

        downvotedQuestion =
            Tuple.first config.downvotes

        onClickUpvote =
            if upvotedQuestion then
                config.removeUpvote
            else
                config.upvote

        onClickDownvote =
            if downvotedQuestion then
                config.removeDownvote
            else
                config.downvote
    in
        div
            [ class "reactive-bottom-bar" ]
            [ span
                [ classList
                    [ ( "dislike-count", True )
                    , ( "selected", downvotedQuestion )
                    ]
                , onClick onClickDownvote
                ]
                [ text <| toString <| Tuple.second <| config.downvotes ]
            , i
                [ classList
                    [ ( "material-icons dislike", True )
                    , ( "selected", downvotedQuestion )
                    ]
                , onClick onClickDownvote
                ]
                [ text "thumb_down" ]
            , span
                [ classList
                    [ ( "like-count", True )
                    , ( "selected", upvotedQuestion )
                    ]
                , onClick onClickUpvote
                ]
                [ text <| toString <| Tuple.second <| config.upvotes ]
            , i
                [ classList
                    [ ( "material-icons like", True )
                    , ( "selected", upvotedQuestion )
                    ]
                , onClick onClickUpvote
                ]
                [ text "thumb_up" ]
            , case ( config.isTidbitAuthor, config.isPinned ) of
                -- Is author, pinned
                ( True, True ) ->
                    i
                        [ class "material-icons pin-icon"
                        , onClick <| config.unpin
                        ]
                        [ text "star" ]

                -- Is author, not pinned
                ( True, False ) ->
                    i
                        [ class "material-icons pin-icon"
                        , onClick <| config.pin
                        ]
                        [ text "star_border" ]

                -- Not Author, pinned
                ( False, True ) ->
                    i [ class "material-icons pin-icon unclickable" ] [ text "star" ]

                -- Not author, not pinned
                ( False, False ) ->
                    Util.hiddenDiv
            , if config.isAuthor then
                i
                    [ class "material-icons edit-icon"
                    , onClick config.edit
                    ]
                    [ text "mode_edit" ]
              else
                Util.hiddenDiv
            , case ( config.isAuthor, config.delete ) of
                ( True, Just deleteMsg ) ->
                    i
                        [ classList
                            [ ( "material-icons delete-icon", True )
                            , ( "warning-mode", config.isDeleteAlreadyClicked )
                            ]
                        , onClick deleteMsg
                        ]
                        [ text <|
                            if config.isDeleteAlreadyClicked then
                                "delete_forever"
                            else
                                "delete"
                        ]

                _ ->
                    Util.hiddenDiv
            ]


{-| The possible tabs within the question view.
-}
type Tab
    = QuestionTab
    | QuestionCommentsTab (Maybe CommentID)
    | AnswersTab
    | AnswerTab AnswerID
    | AnswerCommentsTab AnswerID (Maybe CommentID)


{-| Returns true if `QuestionCommentsTab`.
-}
isQuestionCommentsTab : Tab -> Bool
isQuestionCommentsTab tab =
    case tab of
        QuestionCommentsTab _ ->
            True

        _ ->
            False


{-| Returns true if `AnswerCommentsTab`.
-}
isAnswerCommentsTab : Tab -> Bool
isAnswerCommentsTab tab =
    case tab of
        AnswerCommentsTab _ _ ->
            True

        _ ->
            False
