module Elements.Complex.EditQuestion exposing (..)

import DefaultServices.Editable as Editable
import DefaultServices.InfixFunctions exposing (..)
import DefaultServices.Util as Util
import Html exposing (Html, div, text, textarea)
import Html.Attributes exposing (class, classList, placeholder, value)
import Html.Events exposing (onClick, onInput)
import Models.QA exposing (..)
import ProjectTypeAliases exposing (..)


type alias Model codePointer =
    QuestionEdit codePointer


type Msg
    = TogglePreviewMarkdown
    | OnQuestionTextInput QuestionText


type alias RenderConfig msg codePointer =
    { msgTagger : Msg -> msg
    , isReadyCodePointer : codePointer -> Bool
    , editQuestion : QuestionText -> codePointer -> msg
    }


view : RenderConfig msg codePointer -> Model codePointer -> Html msg
view config model =
    let
        questionText =
            Editable.getBuffer model.questionText

        codePointer =
            Editable.getBuffer model.codePointer

        maybeReadyQuestion =
            case ( Util.justNonblankStringInRange 1 300 questionText, config.isReadyCodePointer codePointer ) of
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
                (div
                    []
                    [ textarea
                        [ placeholder "Edit Question Text"
                        , value questionText
                        , onInput (OnQuestionTextInput >> config.msgTagger)
                        ]
                        []
                    , Util.limitCharsText 300 questionText
                    ]
                )
            , div
                (Util.maybeAttributes
                    [ Just <|
                        classList
                            [ ( "edit-question-submit", True )
                            , ( "not-ready", not isQuestionReady )
                            , ( "hidden", model.previewMarkdown )
                            ]
                    , maybeReadyQuestion
                        ||> (\{ codePointer, questionText } -> onClick <| config.editQuestion questionText codePointer)
                    ]
                )
                [ text "Update Question" ]
            ]


update : Msg -> Model codePointer -> ( Model codePointer, Cmd Msg )
update msg model =
    case msg of
        TogglePreviewMarkdown ->
            ( { model | previewMarkdown = not model.previewMarkdown }, Cmd.none )

        OnQuestionTextInput questionText ->
            ( { model | questionText = Editable.setBuffer model.questionText questionText }, Cmd.none )
