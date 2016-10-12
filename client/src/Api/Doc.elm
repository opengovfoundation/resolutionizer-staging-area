module Api.Doc exposing (CreateResponse, create)

import Doc
import Exts.RemoteData as RemoteData
import Api.Doc.Create


type alias CreateResponse =
    Api.Doc.Create.Response


create : (RemoteData.WebData CreateResponse -> msg) -> Doc.Model -> Cmd msg
create =
    Api.Doc.Create.cmd
