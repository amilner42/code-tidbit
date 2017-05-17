module Elements.EditQuestion exposing (..)

import DefaultServices.Editable as Editable
import DefaultServices.Util as Util
import Html exposing (Html, div, text, textarea)
import Html.Attributes exposing (class, classList, placeholder, value)
import Html.Events exposing (onClick, onInput)
import Models.QA exposing (..)
import ProjectTypeAliases exposing (..)


{-| The model for the `EditQuestion` element.
-}
type alias Model codePointer =
    QuestionEdit codePointer


{-| The Msg for the `EditQuestion` element.
-}
type Msg
    = TogglePreviewMarkdown
    | OnQuestionTextInput QuestionText


{-| The config for rendering a `EditQuestion` element.
-}
type alias RenderConfig msg codePointer =
    { msgTagger : Msg -> msg
    , isReadyCodePointer : codePointer -> Bool
    , editQuestion : QuestionText -> codePointer -> msg
    }


{-| The view for the `EditQuestion` element.
-}
editQuestion : RenderConfig msg codePointer -> Model codePointer -> Html msg
editQuestion config model =
    let
        questionText =
            Editable.getBuffer model.questionText

        codePointer =
            Editable.getBuffer model.codePointer

        maybeReadyQuestion =
            case ( Util.justNonBlankString questionText, config.isReadyCodePointer codePointer ) of
                ( Just questionText, True ) ->
                    Just { questionText = questionText, codePointer = codePointer }

                _ ->
                    Nothing

        isQuestionReady =
            Util.isNotNothing maybeReadyQuestion
    in
        div
            [ class "edit-question" ]
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
            , Util.markdownOr
                model.previewMarkdown
                questionText
                (textarea
                    [ placeholder "Edit Question Text"
                    , value questionText
                    , onInput (OnQuestionTextInput >> config.msgTagger)
                    ]
                    []
                )
            , div
                (Util.maybeAttributes
                    [ Just <|
                        classList
                            [ ( "edit-question-submit", True )
                            , ( "not-ready", not isQuestionReady )
                            , ( "hidden", model.previewMarkdown )
                            ]
                    , Maybe.map
                        (\{ codePointer, questionText } -> onClick <| config.editQuestion questionText codePointer)
                        maybeReadyQuestion
                    ]
                )
                [ text "Update Question" ]
            ]


{-| The update for the `EditQuestion` element.
-}
update : Msg -> Model codePointer -> ( Model codePointer, Cmd Msg )
update msg model =
    case msg of
        TogglePreviewMarkdown ->
            ( { model | previewMarkdown = not model.previewMarkdown }, Cmd.none )

        OnQuestionTextInput questionText ->
            ( { model | questionText = Editable.setBuffer model.questionText questionText }, Cmd.none )
