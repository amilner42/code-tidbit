module Elements.Complex.EditAnswer exposing (..)

import DefaultServices.Editable as Editable
import DefaultServices.Util as Util
import Elements.Simple.Markdown as Markdown
import Html exposing (Html, div, text, textarea)
import Html.Attributes exposing (class, classList, placeholder, value)
import Html.Events exposing (onInput, onClick)
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
    , editAnswer : AnswerText -> msg
    , forQuestion : Question codePointer
    }


view : RenderConfig codePointer msg -> Model -> Html msg
view config ({ previewMarkdown, showQuestion } as model) =
    let
        answerText =
            Editable.getBuffer model.answerText

        maybeReadyAnswer =
            Util.justNonBlankString answerText

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
                (textarea
                    [ classList [ ( "hiding-question", not showQuestion ) ]
                    , placeholder "Edit Answer Text"
                    , value answerText
                    , onInput (config.msgTagger << OnAnswerTextInput)
                    ]
                    []
                )
            , div
                (Util.maybeAttributes
                    [ Just <|
                        classList
                            [ ( "edit-answer-submit", True )
                            , ( "not-ready", not isAnswerReady )
                            , ( "hidden", previewMarkdown )
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
