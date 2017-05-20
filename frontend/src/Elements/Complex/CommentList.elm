module Elements.Complex.CommentList exposing (..)

import DefaultServices.Editable as Editable
import Dict
import Html exposing (Html, div, text, textarea)
import Html.Attributes exposing (class, classList, placeholder, value)
import Html.Events exposing (onInput, onClick)
import Models.QA exposing (..)
import ProjectTypeAliases exposing (..)


type Msg
    = OnNewCommentTextInput CommentText


type alias Model =
    { commentEdits : Dict.Dict CommentID (Editable.Editable CommentText)
    , newCommentText : CommentText
    }


type alias RenderConfig msg comment =
    { msgTagger : Msg -> msg
    , commentBoxRenderConfig : CommentBoxRenderConfig msg (Comment comment)
    , comments : List (Comment comment)
    }


view : RenderConfig msg comment -> Model -> Html msg
view config model =
    div
        [ class "comment-list" ]
        [ div
            [ class "comments" ]
            (List.map (commentBoxView config.commentBoxRenderConfig) config.comments)
        , textarea
            [ class "new-comment-textarea"
            , onInput <| config.msgTagger << OnNewCommentTextInput
            , placeholder "Comment..."
            , value model.newCommentText
            ]
            []
        ]


type alias CommentBoxRenderConfig msg comment =
    { onClickComment : Comment comment -> msg }


commentBoxView : CommentBoxRenderConfig msg (Comment comment) -> Comment comment -> Html msg
commentBoxView config comment =
    div
        [ class "comment-box" ]
        [ text <| comment.commentText ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        OnNewCommentTextInput newCommentText ->
            ( { model | newCommentText = newCommentText }, Cmd.none )
