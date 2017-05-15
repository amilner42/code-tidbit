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
    { tab : Tab
    , question : Question codePointer
    , answers : List Answer
    , questionComments : List QuestionComment
    , answerComments : List AnswerComment
    , onClickQuestionTab : msg
    , onClickAnswersTab : msg
    , onClickQuestionCommentsTab : msg
    , onClickAnswer : Answer -> msg
    , onClickQuestionComment : QuestionComment -> msg
    , onClickAnswerComment : AnswerComment -> msg
    , onClickUpvoteQuestion : msg
    , onClickRemoveUpvoteQuestion : msg
    , onClickDownvoteQuestion : msg
    , onClickRemoveDownvoteQuestion : msg
    , onClickLikeAnswer : Answer -> msg
    , onClickDislikeAnswer : Answer -> msg
    , onClickAnswerQuestion : msg
    }


{-| The possible tabs within the question view.
-}
type Tab
    = QuestionTab
    | QuestionCommentsTab (Maybe CommentID)
    | AnswersTab
    | AnswerTab AnswerID
    | AnswerCommentsTab (Maybe CommentID)


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
        AnswerCommentsTab _ ->
            True

        _ ->
            False


{-| Generates the view for viewing a question.
-}
viewQuestionView : RenderConfig msg codePointer -> Html msg
viewQuestionView config =
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
                    [ ( "tab", True )
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
                let
                    upvotedQuestion =
                        Tuple.first config.question.upvotes

                    downvotedQuestion =
                        Tuple.first config.question.downvotes

                    onClickUpvote =
                        if upvotedQuestion then
                            config.onClickRemoveUpvoteQuestion
                        else
                            config.onClickUpvoteQuestion

                    onClickDownvote =
                        if downvotedQuestion then
                            config.onClickRemoveDownvoteQuestion
                        else
                            config.onClickDownvoteQuestion
                in
                    div
                        [ class "question-tab" ]
                        [ Markdown.githubMarkdown [ class "question-markdown" ] config.question.questionText
                        , div
                            [ class "bottom-bar" ]
                            [ span
                                [ classList
                                    [ ( "dislike-count", True )
                                    , ( "selected", downvotedQuestion )
                                    ]
                                , onClick onClickDownvote
                                ]
                                [ text <| toString <| Tuple.second <| config.question.downvotes ]
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
                                [ text <| toString <| Tuple.second <| config.question.upvotes ]
                            , i
                                [ classList
                                    [ ( "material-icons like", True )
                                    , ( "selected", upvotedQuestion )
                                    ]
                                , onClick onClickUpvote
                                ]
                                [ text "thumb_up" ]
                            ]
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
                                List.map (answerBox config.onClickAnswer) config.answers
                        ]
                    , div
                        [ class "answer-question"
                        , onClick config.onClickAnswerQuestion
                        ]
                        [ text "Answer Question" ]
                    ]

            AnswerTab answerID ->
                -- TODO
                Util.hiddenDiv

            AnswerCommentsTab maybeCommentID ->
                -- TODO
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
            [ span [ class "dislike-count" ] [ text <| toString <| Tuple.second <| answer.upvotes ]
            , i [ class "material-icons dislike" ] [ text "thumb_down" ]
            , span [ class "like-count" ] [ text <| toString <| Tuple.second <| answer.downvotes ]
            , i [ class "material-icons like" ] [ text "thumb_up" ]
            ]
        ]
