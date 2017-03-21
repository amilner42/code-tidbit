module Models.TidbitPointer exposing (..)

{-| -}


{-| A `TidbitPointer` points to a tidbit.
-}
type alias TidbitPointer =
    { tidbitType : TidbitType
    , targetID : String
    }


{-| The current possible tidbit types.
-}
type TidbitType
    = Snipbit
    | Bigbit
