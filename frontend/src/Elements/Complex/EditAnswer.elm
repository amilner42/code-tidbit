module Elements.Complex.EditAnswer exposing (..)

import DefaultServices.Editable as Editable
import DefaultServices.TextFields as TextFields
import DefaultServices.Util as Util
import Elements.Simple.Markdown as Markdown
import ExplanatoryBlurbs exposing (editAnswerPlaceholder)
import Html exposing (Html, div, text)
import Html.Attributes exposing (class, classList, defaultValue, disabled, placeholder)
import Html.Events exposing (onClick, onInput)
import Models.QA exposing (..)
import ProjectTypeAliases exposing (..)


type alias Model =
    AnswerEdit


type Msg
    = ToggleShowQuestion
    | TogglePreviewMarkdown
    | OnAnswerTextInput AnswerText


type alias RenderConfig codePointer msg =
    { msgTagger : Msg -> msg
    , textFieldKeyTracker : TextFields.KeyTracker
    , editAnswerRequestInProgress : Bool
    , editAnswer : AnswerText -> msg
    , forQuestion : Question codePointer
    }


view : RenderConfig codePointer msg -> Model -> Html msg
view config ({ previewMarkdown, showQuestion } as model) =
    let
        answerText =
            Editable.getBuffer model.answerText

        maybeReadyAnswer =
            Util.justNonblankStringInRange 1 1000 answerText

        isAnswerReady =
            Util.isNotNothing maybeReadyAnswer
    in
    div
        [ class "edit-answer" ]
        [ div
            [ classList
                [ ( "display-question", True )
                , ( "hidden", previewMarkdown )
                ]
            , onClick <| config.msgTagger ToggleShowQuestion
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
            , onClick <| config.msgTagger TogglePreviewMarkdown
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
                    "edit-answer"
                    [ classList
                        [ ( "hiding-question", not showQuestion )
                        , ( "cursor-progress", config.editAnswerRequestInProgress )
                        ]
                    , placeholder editAnswerPlaceholder
                    , disabled config.editAnswerRequestInProgress
                    , defaultValue answerText
                    , onInput (config.msgTagger << OnAnswerTextInput)
                    ]
                , Util.limitCharsText 1000 answerText
                ]
            )
        , div
            (Util.maybeAttributes
                [ Just <|
                    classList
                        [ ( "edit-answer-submit", True )
                        , ( "not-ready", not isAnswerReady )
                        , ( "hidden", previewMarkdown )
                        , ( "cursor-progress", config.editAnswerRequestInProgress )
                        ]
                , Maybe.map
                    (onClick << config.editAnswer)
                    maybeReadyAnswer
                ]
            )
            [ text "Update Answer" ]
        ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ToggleShowQuestion ->
            ( { model | showQuestion = not model.showQuestion }, Cmd.none )

        TogglePreviewMarkdown ->
            ( { model | previewMarkdown = not model.previewMarkdown }, Cmd.none )

        OnAnswerTextInput answerText ->
            ( { model | answerText = Editable.setBuffer model.answerText answerText }, Cmd.none )
