module Elements.Simple.QuestionList exposing (..)

import DefaultServices.Util as Util
import Html exposing (Html, div, hr, i, text)
import Html.Attributes exposing (class, classList)
import Html.Events exposing (onClick)
import Models.QA as QA
import Models.Route as Route


type alias RenderConfig codePointer msg =
    { questionBoxRenderConfig : QuestionBoxRenderConfig codePointer msg
    , isHighlighting : Bool
    , allQuestionText : String
    , noQuestionsDuringSearchText : String
    , noQuestionsNotDuringSearchText : String
    , askQuestion : msg
    }


type alias QuestionBoxRenderConfig codePointer msg =
    { questionND : QA.Question codePointer -> Route.NavigationData msg }


view : RenderConfig codePointer msg -> List (QA.Question codePointer) -> Html msg
view ({ questionBoxRenderConfig, askQuestion, isHighlighting, allQuestionText } as config) questions =
    div [ class "questions" ] <|
        [ div
            [ class "questions-title" ]
            [ text <|
                if isHighlighting then
                    "Related Questions"
                else
                    allQuestionText
            ]
        , hr [] []
        , div
            [ class "questions-list" ]
            [ case ( isHighlighting, List.length questions ) of
                ( True, 0 ) ->
                    div [ class "none-found-text" ] [ text <| config.noQuestionsDuringSearchText ]

                ( False, 0 ) ->
                    div [ class "no-questions-text" ] [ text <| config.noQuestionsNotDuringSearchText ]

                _ ->
                    Util.hiddenDiv
            , div [ class "scroll-box" ] <| List.map (questionBoxView questionBoxRenderConfig) questions
            ]
        , div
            [ class "ask-question"
            , onClick askQuestion
            ]
            [ text "Ask Question" ]
        ]


questionBoxView : QuestionBoxRenderConfig codePointer msg -> QA.Question codePointer -> Html msg
questionBoxView { questionND } question =
    Route.navigationNode
        (Just <| questionND question)
        [ class "question-box-nav-node" ]
        [ div
            [ class "question-box" ]
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
        ]
