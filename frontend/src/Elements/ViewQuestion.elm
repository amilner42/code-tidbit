module Elements.ViewQuestion exposing (..)

import DefaultServices.Util as Util
import Elements.Markdown as Markdown
import Html exposing (Html, div, span, text, button, i)
import Html.Attributes exposing (class, classList)
import Html.Events exposing (onClick)
import Models.QA exposing (..)
import ProjectTypeAliases exposing (..)


{-| The full config for rendering a question view.
-}
type alias RenderConfig msg codePointer =
    { userID : Maybe UserID
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
    }


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


{-| Generates the view for viewing a question.
-}
viewQuestionView : RenderConfig msg codePointer -> Html msg
viewQuestionView config =
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
                        [ Markdown.githubMarkdown [ class "question-markdown" ] config.question.questionText
                        , reactiveRatingsBottomBar
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
                    -- TODO
                    Util.hiddenDiv

                AnswersTab ->
                    div
                        [ class "answers-tab" ]
                        [ div
                            [ class "answers-box" ]
                            [ if List.isEmpty config.answers then
                                div [ class "no-answers-text" ] [ text "Be the first to answer the question" ]
                              else
                                div [ class "answers" ] <|
                                    List.map (answerBox config.onClickAnswerTab) config.answers
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
                                , Markdown.githubMarkdown [ class "answer-markdown" ] answer.answerText
                                , reactiveRatingsBottomBar
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
                                [ extendedTopBar False answer ]

                        Nothing ->
                            Util.hiddenDiv
            ]


{-| Renders an answer box.
-}
answerBox : (Answer -> msg) -> Answer -> Html msg
answerBox onClickAnswer answer =
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


{-| The config for rendering the bottom bar with the reactive upvote/downvote buttons.
-}
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
reactiveRatingsBottomBar : ReactiveRatingsBottomBarRenderConfig msg -> Html msg
reactiveRatingsBottomBar config =
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
