module DefaultServices.Editable exposing (..)

-- Inspired by Corey: https://gist.github.com/coreyhaines/cf40b7dca8916b77878c97fdb5c8184e

import Json.Decode as Decode
import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded)
import Json.Encode as Encode


{-| An editable is an item which is either being edited or not being edited.
-}
type Editable ofType
    = NotEditing (NotEditingRecord ofType)
    | Editing (EditingRecord ofType)


{-| If not editing, then an editable simply has a value.
-}
type alias NotEditingRecord ofType =
    { value : ofType }


{-| If editing, then you have the original value and the current editing value which we denote as the buffer.
-}
type alias EditingRecord ofType =
    { originalValue : ofType, buffer : ofType }


{-| Get's the original value out of an editable.
-}
originalValue : Editable ofType -> ofType
originalValue editable =
    case editable of
        NotEditing { value } ->
            value

        Editing { originalValue } ->
            originalValue


{-| Gets the buffer value out of an editable being edited, otherwise returns the value.
-}
getBuffer : Editable ofType -> ofType
getBuffer editable =
    case editable of
        NotEditing { value } ->
            value

        Editing { buffer } ->
            buffer


{-| Puts the editable in editing mode (if it's not already) and sets its buffer.
-}
setBuffer : Editable ofType -> ofType -> Editable ofType
setBuffer editable newBuffer =
    case editable of
        NotEditing _ ->
            setBuffer (startEditing editable) newBuffer

        Editing values ->
            Editing { values | buffer = newBuffer }


{-| Creates an editable being edited.
-}
newEditing : ofType -> Editable ofType
newEditing value =
    Editing { originalValue = value, buffer = value }


{-| Creates an editable not being edited.
-}
newNotEditing : ofType -> Editable ofType
newNotEditing value =
    NotEditing { value = value }


{-| If not editing, switches to editing mode and sets the buffer to the original value.
-}
startEditing : Editable ofType -> Editable ofType
startEditing editable =
    case editable of
        NotEditing { value } ->
            newEditing value

        _ ->
            editable


{-| If editing, switches to not editing using the value of the buffer as the new value.
-}
finishEditing : Editable ofType -> Editable ofType
finishEditing editable =
    case editable of
        NotEditing _ ->
            editable

        Editing { buffer } ->
            NotEditing { value = buffer }


{-| Cancels an editable and sends it back to it's original value.
-}
cancelEditing : Editable ofType -> Editable ofType
cancelEditing editable =
    case editable of
        NotEditing _ ->
            editable

        Editing { originalValue } ->
            NotEditing { value = originalValue }


{-| Returns true if an editable is currently being edited.
-}
isEditing : Editable ofType -> Bool
isEditing editable =
    case editable of
        NotEditing _ ->
            False

        Editing _ ->
            True


{-| Checks if an editable being edited is different than it's original value.
-}
hasChanged : Editable comparable -> Bool
hasChanged editable =
    case editable of
        NotEditing _ ->
            False

        Editing { originalValue, buffer } ->
            originalValue /= buffer


{-| Encodes an editable.
-}
encoder : (ofType -> Encode.Value) -> Editable ofType -> Encode.Value
encoder ofTypeEncoder editable =
    case editable of
        Editing { originalValue, buffer } ->
            Encode.object
                [ ( "originalValue", ofTypeEncoder originalValue )
                , ( "buffer", ofTypeEncoder buffer )
                ]

        NotEditing { value } ->
            Encode.object
                [ ( "value", ofTypeEncoder value ) ]


{-| Decodes an editable.
-}
decoder : Decode.Decoder ofType -> Decode.Decoder (Editable ofType)
decoder decodeOfType =
    let
        decodeEditing : Decode.Decoder (Editable ofType)
        decodeEditing =
            decode EditingRecord
                |> required "originalValue" decodeOfType
                |> required "buffer" decodeOfType
                |> Decode.map Editing

        decodeNotEditing : Decode.Decoder (Editable ofType)
        decodeNotEditing =
            decode NotEditingRecord
                |> required "value" decodeOfType
                |> Decode.map NotEditing
    in
        Decode.oneOf [ decodeEditing, decodeNotEditing ]
