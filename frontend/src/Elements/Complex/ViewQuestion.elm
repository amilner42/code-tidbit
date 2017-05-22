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


type alias Model =
    { questionCommentEdits : Dict.Dict CommentID (Editable.Editable CommentText)
    , newQuestionComment : CommentText
    , answerCommentEdits : Dict.Dict CommentID (Editable.Editable CommentText)
    , newAnswerComments : Dict.Dict AnswerID CommentText
    , deletingComments : Set.Set CommentID
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
    , onClickQuestionTab : msg
    , onClickAnswersTab : msg
    , onClickQuestionCommentsTab : msg
    , onClickAnswerTab : Answer -> msg
    , onClickAnswerCommentsTab : Answer -> msg
    , onClickQuestionComment : QuestionComment -> msg
    , onClickAnswerComment : AnswerComment -> msg
    , onClickUpvoteQuestion : msg
    , onClickRemoveUpvoteQuestion : msg
    , onClickDownvoteQuestion : msg
    , onClickRemoveDownvoteQuestion : msg
    , onClickUpvoteAnswer : Answer -> msg
    , onClickRemoveUpvoteAnswer : Answer -> msg
    , onClickDownvoteAnswer : Answer -> msg
    , onClickRemoveDownvoteAnswer : Answer -> msg
    , onClickPinQuestion : msg
    , onClickUnpinQuestion : msg
    , onClickPinAnswer : Answer -> msg
    , onClickUnpinAnswer : Answer -> msg
    , onClickAnswerQuestion : msg
    , onClickEditQuestion : msg
    , onClickEditAnswer : Answer -> msg
    , submitCommentOnQuestion : CommentText -> msg
    , submitCommentOnAnswer : AnswerID -> CommentText -> msg
    , deleteCommentOnQuestion : CommentID -> msg
    , deleteCommentOnAnswer : CommentID -> msg
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
                    , onClick (config.onClickAnswerTab answer)
                    ]
                    [ text "ANSWER" ]
                , div
                    [ classList
                        [ ( "tab right-tab", True )
                        , ( "selected", not isAnswerTab )
                        ]
                    , onClick (config.onClickAnswerCommentsTab answer)
                    ]
                    [ text "COMMENTS" ]
                ]
    in
        div [ class "view-question" ] <|
            [ div
                [ class "top-bar" ]
                [ div
                    [ classList
                        [ ( "tab", True )
                        , ( "selected", config.tab == QuestionTab )
                        ]
                    , onClick config.onClickQuestionTab
                    ]
                    [ text "QUESTION" ]
                , div
                    [ classList
                        [ ( "tab center-tab", True )
                        , ( "selected", isQuestionCommentsTab config.tab )
                        ]
                    , onClick config.onClickQuestionCommentsTab
                    ]
                    [ text "COMMENTS" ]
                , div
                    [ classList
                        [ ( "tab", True )
                        , ( "selected", (==) AnswersTab config.tab )
                        ]
                    , onClick config.onClickAnswersTab
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
                            , onClickUpvote = config.onClickUpvoteQuestion
                            , onClickRemoveUpvote = config.onClickRemoveUpvoteQuestion
                            , onClickDownvote = config.onClickDownvoteQuestion
                            , onClickRemoveDownvote = config.onClickRemoveDownvoteQuestion
                            , onClickPin = config.onClickPinQuestion
                            , onClickUnpin = config.onClickUnpinQuestion
                            , pinned = config.question.pinned
                            , isAuthor = config.userID == (Just config.question.authorID)
                            , isTidbitAuthor = config.userID == (Just config.tidbitAuthorID)
                            , onClickEdit = config.onClickEditQuestion
                            }
                        ]

                QuestionCommentsTab maybeCommentID ->
                    CommentList.view
                        { msgTagger = config.msgTagger << QuestionCommentListMsg
                        , userID = config.userID
                        , small = False
                        , comments = config.questionComments
                        , submitNewComment = config.submitCommentOnQuestion
                        , onClickComment = config.onClickQuestionComment
                        , deleteComment = config.deleteCommentOnQuestion
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
                                    List.map (answerBoxView config.onClickAnswerTab) config.answers
                            ]
                        , div
                            [ class "answer-question"
                            , onClick config.onClickAnswerQuestion
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
                                    , onClickUpvote = config.onClickUpvoteAnswer answer
                                    , onClickRemoveUpvote = config.onClickRemoveUpvoteAnswer answer
                                    , onClickDownvote = config.onClickDownvoteAnswer answer
                                    , onClickRemoveDownvote = config.onClickRemoveDownvoteAnswer answer
                                    , onClickPin = config.onClickPinAnswer answer
                                    , onClickUnpin = config.onClickUnpinAnswer answer
                                    , pinned = answer.pinned
                                    , isAuthor = config.userID == (Just answer.authorID)
                                    , isTidbitAuthor = config.userID == (Just config.tidbitAuthorID)
                                    , onClickEdit = config.onClickEditAnswer answer
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
                                    , small = True
                                    , comments = config.answerComments
                                    , submitNewComment = config.submitCommentOnAnswer answer.id
                                    , onClickComment = config.onClickAnswerComment
                                    , deleteComment = config.deleteCommentOnAnswer
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


answerBoxView : (Answer -> msg) -> Answer -> Html msg
answerBoxView onClickAnswer answer =
    div
        [ class "answer-box"
        , onClick <| onClickAnswer answer
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
    , onClickUpvote : msg
    , onClickRemoveUpvote : msg
    , onClickDownvote : msg
    , onClickRemoveDownvote : msg
    , onClickPin : msg
    , onClickUnpin : msg
    , pinned : Bool
    , isAuthor : Bool
    , isTidbitAuthor : Bool
    , onClickEdit : msg
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
                config.onClickRemoveUpvote
            else
                config.onClickUpvote

        onClickDownvote =
            if downvotedQuestion then
                config.onClickRemoveDownvote
            else
                config.onClickDownvote
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
            , case ( config.isTidbitAuthor, config.pinned ) of
                -- Is author, pinned
                ( True, True ) ->
                    i
                        [ class "material-icons pin-icon"
                        , onClick <| config.onClickUnpin
                        ]
                        [ text "star" ]

                -- Is author, not pinned
                ( True, False ) ->
                    i
                        [ class "material-icons pin-icon"
                        , onClick <| config.onClickPin
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
                    , onClick config.onClickEdit
                    ]
                    [ text "mode_edit" ]
              else
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
