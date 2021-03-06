module Elements.Complex.AskQuestion exposing (..)

import DefaultServices.InfixFunctions exposing (..)
import DefaultServices.TextFields as TextFields
import DefaultServices.Util as Util
import Elements.Simple.Markdown as Markdown
import ExplanatoryBlurbs exposing (askQuestionPlaceholder)
import Html exposing (Html, div, text)
import Html.Attributes exposing (class, classList, defaultValue, disabled, placeholder)
import Html.Events exposing (onClick, onInput)
import Models.QA exposing (..)
import Models.Route as Route
import ProjectTypeAliases exposing (..)


type Msg
    = TogglePreviewMarkdown
    | OnQuestionTextInput String


type alias Model codePointer =
    NewQuestion codePointer


type alias RenderConfig msg codePointer =
    { subMsg : Msg -> msg
    , textFieldKeyTracker : TextFields.KeyTracker
    , askQuestionRequestInProgress : Bool
    , allQuestionsND : Route.NavigationData msg
    , askQuestion : codePointer -> QuestionText -> msg
    , isReadyCodePointer : codePointer -> Bool
    }


view : RenderConfig msg codePointer -> Model codePointer -> Html msg
view config model =
    let
        maybeReadyQuestion =
            case ( model.codePointer, Util.justNonblankStringInRange 1 300 model.questionText ) of
                ( Just codePointer, Just questionText ) ->
                    if config.isReadyCodePointer codePointer then
                        Just { codePointer = codePointer, questionText = questionText }
                    else
                        Nothing

                _ ->
                    Nothing

        isQuestionReady =
            Util.isNotNothing maybeReadyQuestion
    in
    div
        [ class "ask-question" ]
        [ Route.navigationNode
            (Just config.allQuestionsND)
            [ class "link-nav-node" ]
            [ div
                [ class "link qa-top-right-link" ]
                [ text "see all questions" ]
            ]
        , div
            [ class "preview-markdown"
            , onClick <| config.subMsg TogglePreviewMarkdown
            ]
            [ text <|
                if model.previewMarkdown then
                    "Close Preview"
                else
                    "Markdown Preview"
            ]
        , if model.previewMarkdown then
            Markdown.view [] model.questionText
          else
            div
                []
                [ TextFields.textarea
                    config.textFieldKeyTracker
                    "ask-question"
                    [ classList [ ( "cursor-progress", config.askQuestionRequestInProgress ) ]
                    , placeholder askQuestionPlaceholder
                    , onInput (OnQuestionTextInput >> config.subMsg)
                    , defaultValue model.questionText
                    , disabled <| config.askQuestionRequestInProgress
                    ]
                , Util.limitCharsText 300 model.questionText
                ]
        , div
            (Util.maybeAttributes
                [ Just <|
                    classList
                        [ ( "ask-question-submit", True )
                        , ( "not-ready", not isQuestionReady )
                        , ( "hidden", model.previewMarkdown )
                        , ( "cursor-progress", config.askQuestionRequestInProgress )
                        ]
                , maybeReadyQuestion
                    ||> (\{ codePointer, questionText } -> onClick <| config.askQuestion codePointer questionText)
                ]
            )
            [ text "Ask Question" ]
        ]


update : Msg -> Model codePointer -> ( Model codePointer, Cmd Msg )
update msg model =
    case msg of
        TogglePreviewMarkdown ->
            ( { model | previewMarkdown = not model.previewMarkdown }, Cmd.none )

        OnQuestionTextInput questionText ->
            ( { model | questionText = questionText }, Cmd.none )
