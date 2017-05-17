module Elements.AskQuestion exposing (..)

import DefaultServices.Util as Util
import Elements.Markdown as Markdown
import Html exposing (Html, div, text, textarea)
import Html.Attributes exposing (class, classList, placeholder, value)
import Html.Events exposing (onInput, onClick)
import Models.QA exposing (..)
import ProjectTypeAliases exposing (..)


{-| The Msg for the `AskQuestion` element.
-}
type Msg
    = TogglePreviewMarkdown
    | OnQuestionTextInput String


{-| The Model for the `AskQuestion` element.
-}
type alias Model codePointer =
    NewQuestion codePointer


{-| The config for rendering the `AskQuestion` element.
-}
type alias RenderConfig msg codePointer =
    { msgTagger : Msg -> msg
    , askQuestion : codePointer -> QuestionText -> msg
    , isReadyCodePointer : codePointer -> Bool
    }


{-| The view for the `AskQuestion` element.
-}
askQuestion : RenderConfig msg codePointer -> Model codePointer -> Html msg
askQuestion config model =
    let
        maybeReadyQuestion =
            case ( model.codePointer, Util.justNonBlankString model.questionText ) of
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
            [ div
                [ class "preview-markdown"
                , onClick <| config.msgTagger TogglePreviewMarkdown
                ]
                [ text <|
                    if model.previewMarkdown then
                        "Close Preview"
                    else
                        "Markdown Preview"
                ]
            , if model.previewMarkdown then
                Markdown.githubMarkdown [] model.questionText
              else
                textarea
                    [ placeholder "Highlight code and ask your question"
                    , onInput (OnQuestionTextInput >> config.msgTagger)
                    , value model.questionText
                    ]
                    []
            , div
                (Util.maybeAttributes
                    [ Just <|
                        classList
                            [ ( "ask-question-submit", True )
                            , ( "not-ready", not isQuestionReady )
                            , ( "hidden", model.previewMarkdown )
                            ]
                    , Maybe.map
                        (\{ codePointer, questionText } -> onClick <| config.askQuestion codePointer questionText)
                        maybeReadyQuestion
                    ]
                )
                [ text "Ask Question" ]
            ]


{-| Handles updates for the `AskQuestion` element.
-}
update : Msg -> Model codePointer -> ( Model codePointer, Cmd Msg )
update msg model =
    case msg of
        TogglePreviewMarkdown ->
            ( { model | previewMarkdown = not model.previewMarkdown }, Cmd.none )

        OnQuestionTextInput questionText ->
            ( { model | questionText = questionText }, Cmd.none )
