module Models.CreateData exposing (..)

import Models.TidbitType as TidbitType


{-| All the data required for the create page.
-}
type alias CreateData =
    { showInfoFor : Maybe TidbitType.TidbitType
    }


{-| Sets `showInfoFor`.
-}
setShowInfoFor : Maybe TidbitType.TidbitType -> CreateData -> CreateData
setShowInfoFor maybeTidbitType createData =
    { createData
        | showInfoFor = maybeTidbitType
    }


{-| The default create page data.
-}
defaultCreateData : CreateData
defaultCreateData =
    { showInfoFor = Nothing
    }
