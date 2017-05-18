module Elements.Simple.QuestionList exposing (..)

import DefaultServices.Util as Util
import Html exposing (Html, div, text, i, hr)
import Html.Attributes exposing (class, classList)
import Html.Events exposing (onClick)
import Models.QA as QA


type alias RenderConfig codePointer msg =
    { questionBoxRenderConfig : QuestionBoxRenderConfig codePointer msg
    , onClickAskQuestion : msg
    , isHighlighting : Bool
    }


type alias QuestionBoxRenderConfig codePointer msg =
    { onClickQuestionBox : QA.Question codePointer -> msg }


view : RenderConfig codePointer msg -> List (QA.Question codePointer) -> Html msg
view { questionBoxRenderConfig, onClickAskQuestion, isHighlighting } questions =
    div [ class "questions" ] <|
        [ div [ class "questions-title" ]
            [ text <|
                if isHighlighting then
                    "Related Questions"
                else
                    "All Questions"
            ]
        , hr [] []
        , div
            [ class "questions-list" ]
            [ case ( isHighlighting, List.length questions ) of
                ( True, 0 ) ->
                    div [ class "none-found-text" ] [ text "None found" ]

                ( False, 0 ) ->
                    div [ class "no-questions-text" ] [ text "Be the first to ask a question" ]

                _ ->
                    Util.hiddenDiv
            , div [ class "scroll-box" ] <| List.map (questionBoxView questionBoxRenderConfig) questions
            ]
        , div
            [ class "ask-question"
            , onClick onClickAskQuestion
            ]
            [ text "Ask question" ]
        ]


questionBoxView : QuestionBoxRenderConfig codePointer msg -> QA.Question codePointer -> Html msg
questionBoxView { onClickQuestionBox } question =
    div
        [ class "question-box"
        , onClick <| onClickQuestionBox question
        ]
        [ div [ class "question-text" ] [ text question.questionText ]
        , div
            [ class "upvotes-and-downvotes" ]
            [ div [ class "email" ] [ text question.authorEmail ]
            , div
                [ classList
                    [ ( "downvotes", True )
                    , ( "user-downvoted", Tuple.first question.downvotes )
                    ]
                ]
                [ i [ class "material-icons" ] [ text "thumb_down" ]
                , text <| toString <| Tuple.second question.downvotes
                ]
            , div
                [ classList
                    [ ( "upvotes", True )
                    , ( "user-upvoted", Tuple.first question.upvotes )
                    ]
                ]
                [ i [ class "material-icons" ] [ text "thumb_up" ]
                , text <| toString <| Tuple.second question.upvotes
                ]
            , div
                [ classList
                    [ ( "pinned", True )
                    , ( "hidden", not question.pinned )
                    ]
                ]
                [ i [ class "material-icons" ] [ text "star" ] ]
            ]
        ]
