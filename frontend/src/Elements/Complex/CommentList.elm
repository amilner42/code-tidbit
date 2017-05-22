module Elements.Complex.CommentList exposing (..)

import Date
import Date.Format
import DefaultServices.Editable as Editable
import DefaultServices.InfixFunctions exposing (..)
import DefaultServices.Util as Util
import Dict
import Html exposing (Html, div, span, i, text, textarea)
import Html.Attributes exposing (class, classList, placeholder, value)
import Html.Events exposing (onInput, onClick)
import Models.QA exposing (..)
import ProjectTypeAliases exposing (..)
import Set


type Msg
    = OnNewCommentTextInput CommentText
    | AddToDeletingComments CommentID
    | StartEditing CommentID CommentText
    | CancelEditing CommentID
    | OnEditCommentInput CommentID CommentText


type alias Model =
    { commentEdits : Dict.Dict CommentID (Editable.Editable CommentText)
    , newCommentText : CommentText
    , deletingComments : Set.Set CommentID
    }


type alias RenderConfig msg comment =
    { msgTagger : Msg -> msg
    , userID : Maybe UserID
    , small : Bool
    , comments : List (Comment comment)
    , submitNewComment : CommentText -> msg
    , editComment : CommentID -> CommentText -> msg
    , onClickComment : Comment comment -> msg
    , deleteComment : CommentID -> msg
    }


view : RenderConfig msg comment -> Model -> Html msg
view config model =
    div
        [ class "comment-list" ]
        [ div
            [ classList [ ( "comments-wrapper", True ), ( "small", config.small ) ] ]
            [ Util.keyedDiv
                [ class "comments" ]
                (if List.isEmpty config.comments then
                    [ ( "no-comments-text"
                      , span [ class "no-comments-text" ] [ text "No Comments" ]
                      )
                    ]
                 else
                    List.map
                        (\comment -> ( comment.id, commentBoxView config model comment ))
                        config.comments
                )
            ]
        , textarea
            [ class "new-comment-textarea"
            , onInput <| config.msgTagger << OnNewCommentTextInput
            , placeholder "Add Comment..."
            , value model.newCommentText
            ]
            []
        , div
            (Util.maybeAttributes
                [ Just <|
                    classList
                        [ ( "submit-comment", True )
                        , ( "disabled", Util.isNothing <| Util.justNonBlankString model.newCommentText )
                        ]
                , Util.justNonBlankString model.newCommentText ||> onClick << config.submitNewComment
                ]
            )
            [ text "Submit Comment" ]
        ]


commentBoxView : RenderConfig msg comment -> Model -> Comment comment -> Html msg
commentBoxView config { deletingComments, commentEdits } comment =
    let
        isBeingDeleted =
            Set.member comment.id deletingComments

        maybeCommentEdit =
            Dict.get comment.id commentEdits

        isCommentAuthor =
            config.userID == (Just comment.authorID)
    in
        div
            [ class "comment-box" ]
            [ case maybeCommentEdit of
                Just commentEdit ->
                    textarea
                        [ class "comment-box-text-edit-mode"
                        , placeholder "Edit comment..."
                        , value <| Editable.getBuffer commentEdit
                        , onInput <| config.msgTagger << OnEditCommentInput comment.id
                        ]
                        []

                Nothing ->
                    span [ class "comment-box-text" ] [ text <| comment.commentText ]
            , div
                [ class "comment-box-bottom" ]
                [ if isCommentAuthor then
                    div
                        [ class "author-icons" ]
                        (case maybeCommentEdit of
                            Just commentEdit ->
                                [ i
                                    [ class "material-icons cancel-edit"
                                    , onClick <| config.msgTagger <| CancelEditing comment.id
                                    ]
                                    [ text "cancel" ]
                                , i
                                    (Util.maybeAttributes
                                        [ Just <|
                                            classList
                                                [ ( "material-icons submit-edit", True )
                                                , ( "not-allowed"
                                                  , Util.isNothing <|
                                                        Util.justNonBlankString <|
                                                            Editable.getBuffer commentEdit
                                                  )
                                                ]
                                        , Editable.getBuffer commentEdit
                                            |> Util.justNonBlankString
                                            ||> config.editComment comment.id
                                            ||> onClick
                                        ]
                                    )
                                    [ text "check_circle" ]
                                ]

                            Nothing ->
                                [ i
                                    [ classList
                                        [ ( "material-icons delete-comment", True )
                                        , ( "delete-warning", isBeingDeleted )
                                        ]
                                    , onClick <|
                                        if isBeingDeleted then
                                            config.deleteComment comment.id
                                        else
                                            config.msgTagger <| AddToDeletingComments comment.id
                                    ]
                                    [ text <|
                                        if isBeingDeleted then
                                            "delete_forever"
                                        else
                                            "delete"
                                    ]
                                , i
                                    [ class "material-icons edit-comment"
                                    , onClick <| config.msgTagger <| StartEditing comment.id comment.commentText
                                    ]
                                    [ text "edit_mode" ]
                                ]
                        )
                  else
                    span
                        [ class "email" ]
                        [ text <| comment.authorEmail ]
                , span
                    [ class "date" ]
                    [ text <| Date.Format.format "%m/%d/%Y" comment.createdAt ]
                ]
            ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        OnNewCommentTextInput newCommentText ->
            ( { model | newCommentText = newCommentText }, Cmd.none )

        AddToDeletingComments commentID ->
            ( { model | deletingComments = Set.insert commentID model.deletingComments }, Cmd.none )

        StartEditing commentID commentText ->
            -- If already editing then do nothing.
            if Dict.member commentID model.commentEdits then
                ( model, Cmd.none )
            else
                ( { model | commentEdits = Dict.insert commentID (Editable.newEditing commentText) model.commentEdits }
                , Cmd.none
                )

        CancelEditing commentID ->
            ( { model
                | commentEdits = Dict.remove commentID model.commentEdits
                , deletingComments = Set.remove commentID model.deletingComments
              }
            , Cmd.none
            )

        OnEditCommentInput commentID commentText ->
            ( { model
                | commentEdits =
                    Dict.update
                        commentID
                        (Maybe.map (\commentEdit -> Editable.setBuffer commentEdit commentText))
                        model.commentEdits
              }
            , Cmd.none
            )
