module Elements.Complex.AnswerQuestion exposing (..)

import DefaultServices.Util as Util
import Elements.Simple.Markdown as Markdown
import Html exposing (Html, div, text, textarea)
import Html.Attributes exposing (class, classList, value, placeholder)
import Html.Events exposing (onInput, onClick)
import Models.QA exposing (..)
import ProjectTypeAliases exposing (..)


type alias Model =
    NewAnswer


type Msg
    = ToggleShowQuestion
    | TogglePreviewMarkdown
    | OnAnswerTextInput AnswerText


type alias RenderConfig codePointer msg =
    { msgTagger : Msg -> msg
    , answerQuestion : AnswerText -> msg
    , goToAllAnswers : msg
    , forQuestion : Question codePointer
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
            [ div
                [ class "link qa-top-right-link"
                , onClick config.goToAllAnswers
                ]
                [ text "see all answers" ]
            , div
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
                    [ textarea
                        [ classList [ ( "hiding-question", not showQuestion ) ]
                        , placeholder "Answer Question"
                        , onInput (config.msgTagger << OnAnswerTextInput)
                        , value answerText
                        ]
                        []
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
