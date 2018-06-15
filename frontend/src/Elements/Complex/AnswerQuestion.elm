module Elements.Complex.AnswerQuestion exposing (..)

import DefaultServices.TextFields as TextFields
import DefaultServices.Util as Util
import Elements.Simple.Markdown as Markdown
import ExplanatoryBlurbs exposing (answerQuestionPlaceholder)
import Html exposing (Html, div, text)
import Html.Attributes exposing (class, classList, defaultValue, disabled, placeholder)
import Html.Events exposing (onClick, onInput)
import Models.QA exposing (..)
import Models.Route as Route
import ProjectTypeAliases exposing (..)


type alias Model =
    NewAnswer


type Msg
    = ToggleShowQuestion
    | TogglePreviewMarkdown
    | OnAnswerTextInput AnswerText


type alias RenderConfig codePointer msg =
    { subMsg : Msg -> msg
    , textFieldKeyTracker : TextFields.KeyTracker
    , forQuestion : Question codePointer
    , answerQuestionRequestInProgress : Bool
    , allAnswersND : Route.NavigationData msg
    , answerQuestion : AnswerText -> msg
    }


view : RenderConfig codePointer msg -> Model -> Html msg
view config { previewMarkdown, showQuestion, answerText } =
    let
        maybeReadyAnswer =
            Util.justNonblankStringInRange 1 1000 answerText

        isAnswerReady =
            Util.isNotNothing maybeReadyAnswer
    in
    div
        [ class "answer-question" ]
        [ Route.navigationNode
            (Just config.allAnswersND)
            [ class "link-nav-node" ]
            [ div
                [ class "link qa-top-right-link" ]
                [ text "see all answers" ]
            ]
        , div
            [ classList
                [ ( "display-question", True )
                , ( "hidden", previewMarkdown )
                ]
            , onClick <| config.subMsg ToggleShowQuestion
            ]
            [ text <|
                if showQuestion then
                    "Hide Question"
                else
                    "Show Question"
            ]
        , Markdown.view
            [ classList
                [ ( "question", True )
                , ( "hidden", previewMarkdown || not showQuestion )
                ]
            ]
            config.forQuestion.questionText
        , div
            [ classList
                [ ( "preview-markdown", True )
                , ( "previewing-markdown", previewMarkdown )
                , ( "hiding-question", not showQuestion )
                ]
            , onClick <| config.subMsg TogglePreviewMarkdown
            ]
            [ text <|
                if previewMarkdown then
                    "Close Preview"
                else
                    "Markdown Preview"
            ]
        , Util.markdownOr
            previewMarkdown
            answerText
            (div
                []
                [ TextFields.textarea
                    config.textFieldKeyTracker
                    "answer-question"
                    [ classList
                        [ ( "hiding-question", not showQuestion )
                        , ( "cursor-progress", config.answerQuestionRequestInProgress )
                        ]
                    , placeholder answerQuestionPlaceholder
                    , disabled config.answerQuestionRequestInProgress
                    , onInput (config.subMsg << OnAnswerTextInput)
                    , defaultValue answerText
                    ]
                , Util.limitCharsText 1000 answerText
                ]
            )
        , div
            (Util.maybeAttributes
                [ Just <|
                    classList
                        [ ( "answer-question-submit", True )
                        , ( "hidden", previewMarkdown )
                        , ( "not-ready", not isAnswerReady )
                        , ( "cursor-progress", config.answerQuestionRequestInProgress )
                        ]
                , Maybe.map (onClick << config.answerQuestion) maybeReadyAnswer
                ]
            )
            [ text "Submit Answer" ]
        ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ToggleShowQuestion ->
            ( { model | showQuestion = not model.showQuestion }, Cmd.none )

        TogglePreviewMarkdown ->
            ( { model | previewMarkdown = not model.previewMarkdown }, Cmd.none )

        OnAnswerTextInput answerText ->
            ( { model | answerText = answerText }, Cmd.none )
