module Elements.Complex.AskQuestion exposing (..)

import Api exposing (api)
import DefaultServices.InfixFunctions exposing (..)
import DefaultServices.TextFields as TextFields
import DefaultServices.Util as Util
import Elements.Simple.Markdown as Markdown
import ExplanatoryBlurbs exposing (askQuestionPlaceholder)
import Html exposing (Html, div, text)
import Html.Attributes exposing (class, classList, defaultValue, disabled, placeholder)
import Html.Events exposing (onClick, onInput)
import Models.QA exposing (..)
import Models.RequestTracker as RT
import Models.Route as Route
import Models.TidbitPointer as TidbitPointer
import ProjectTypeAliases exposing (..)


type Msg
    = TogglePreviewMarkdown TidbitPointer.TidbitPointer
    | OnQuestionTextInput TidbitPointer.TidbitPointer String
    | AskQuestion TidbitPointer.TidbitPointer
    | OnAskQuestionSuccess
    | OnAskQuestionFailure


type alias Model codePointer =
    { qaState : QAState codePointer
    , apiRequestTracker : RT.RequestTracker
    }


type alias RenderConfig msg codePointer =
    { subMsg : Msg -> msg
    , textFieldKeyTracker : TextFields.KeyTracker
    , tidbitPointer : TidbitPointer.TidbitPointer
    , allQuestionsND : Route.NavigationData msg
    , isReadyCodePointer : codePointer -> Bool
    }


view : RenderConfig msg codePointer -> Model codePointer -> Html msg
view config model =
    let
        newQuestion =
            model.qaState
                |> getNewQuestion config.tidbitPointer.targetID
                ?> defaultNewQuestion

        maybeReadyQuestion =
            case ( newQuestion.codePointer, Util.justNonblankStringInRange 1 300 newQuestion.questionText ) of
                ( Just codePointer, Just questionText ) ->
                    if config.isReadyCodePointer codePointer then
                        Just { codePointer = codePointer, questionText = questionText }
                    else
                        Nothing

                _ ->
                    Nothing

        isQuestionReady =
            Util.isNotNothing maybeReadyQuestion

        requestInProgress =
            RT.isMakingRequest model.apiRequestTracker (RT.AskQuestion config.tidbitPointer.tidbitType)
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
            , onClick <| config.subMsg <| TogglePreviewMarkdown config.tidbitPointer
            ]
            [ text <|
                if newQuestion.previewMarkdown then
                    "Close Preview"
                else
                    "Markdown Preview"
            ]
        , if newQuestion.previewMarkdown then
            Markdown.view [] newQuestion.questionText
          else
            div
                []
                [ TextFields.textarea
                    config.textFieldKeyTracker
                    "ask-question"
                    [ classList [ ( "cursor-progress", requestInProgress ) ]
                    , placeholder askQuestionPlaceholder
                    , onInput (OnQuestionTextInput config.tidbitPointer >> config.subMsg)
                    , defaultValue newQuestion.questionText
                    , disabled <| requestInProgress
                    ]
                , Util.limitCharsText 300 newQuestion.questionText
                ]
        , div
            (Util.maybeAttributes
                [ Just <|
                    classList
                        [ ( "ask-question-submit", True )
                        , ( "not-ready", not isQuestionReady )
                        , ( "hidden", newQuestion.previewMarkdown )
                        , ( "cursor-progress", requestInProgress )
                        ]
                , maybeReadyQuestion
                    ||> (\{ codePointer, questionText } -> onClick <| config.subMsg <| AskQuestion config.tidbitPointer)
                ]
            )
            [ text "Ask Question" ]
        ]


update : Msg -> Model codePointer -> ( Model codePointer, Cmd Msg )
update msg model =
    let
        updateNewQuestionState tidbitID updater =
            { model
                | qaState =
                    updateNewQuestion
                        tidbitID
                        updater
                        model.qaState
            }
    in
    case msg of
        TogglePreviewMarkdown tidbitPointer ->
            ( updateNewQuestionState
                tidbitPointer.targetID
                (\newQuestion -> { newQuestion | previewMarkdown = not newQuestion.previewMarkdown })
            , Cmd.none
            )

        OnQuestionTextInput tidbitPointer questionText ->
            ( updateNewQuestionState
                tidbitPointer.targetID
                (\newQuestion -> { newQuestion | questionText = questionText })
            , Cmd.none
            )

        AskQuestion tidbitPointer ->
            -- TODO
            if RT.isMakingRequest model.apiRequestTracker (RT.AskQuestion tidbitPointer.tidbitType) then
                ( model, Cmd.none )
            else
                ( { model | apiRequestTracker = RT.startRequest (RT.AskQuestion tidbitPointer.tidbitType) model.apiRequestTracker }
                , Cmd.none
                )

        OnAskQuestionSuccess ->
            -- TODO
            ( model, Cmd.none )

        OnAskQuestionFailure ->
            -- TODO
            ( model, Cmd.none )



-- AskQuestion snipbitID codePointer questionText ->
--     let
--         askQuestionAction =
--             common.justProduceCmd <|
--                 api.post.askQuestionOnSnipbit
--                     snipbitID
--                     questionText
--                     codePointer
--                     (common.subMsg << OnAskQuestionFailure)
--                     (common.subMsg << OnAskQuestionSuccess snipbitID)
--     in
--     common.makeSingletonRequest (RT.AskQuestion TidbitPointer.Snipbit) askQuestionAction
-- OnAskQuestionSuccess snipbitID question ->
--     (case model.qa of
--         Just qa ->
--             ( { model
--                 | qa = Just { qa | questions = QA.sortRateableContent <| question :: qa.questions }
--                 , qaState = QA.updateNewQuestion snipbitID (always QA.defaultNewQuestion) model.qaState
--               }
--             , shared
--             , Route.navigateTo <|
--                 Route.ViewSnipbitQuestionPage
--                     (Route.getFromStoryQueryParamOnViewSnipbitRoute shared.route)
--                     Nothing
--                     snipbitID
--                     question.id
--             )
--
--         Nothing ->
--             common.doNothing
--     )
--         |> common.andFinishRequest (RT.AskQuestion TidbitPointer.Snipbit)
--
-- OnAskQuestionFailure apiError ->
--     common.justSetModalError apiError
--         |> common.andFinishRequest (RT.AskQuestion TidbitPointer.Snipbit)
