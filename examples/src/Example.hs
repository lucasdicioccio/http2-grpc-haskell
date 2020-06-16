{-# LANGUAGE DataKinds #-}
{-# LANGUAGE OverloadedStrings #-}

module Example where

import Control.Monad (void)
import Control.Monad.IO.Class (liftIO)
import Proto.Protos.Grpcbin
import Proto.Protos.Grpcbin_Fields
import Network.GRPC.Client
import Network.HTTP2.Client
import Network.GRPC.Client.Helpers
import Network.GRPC.HTTP2.Encoding
import Lens.Micro
import Network.GRPC.HTTP2.ProtoLens

import Data.ProtoLens

main :: IO ()
main = do
  let encoding = Encoding uncompressed
  let decoding = Decoding uncompressed
  let host = "grpcb.in"
  let port = 9000
  void $ runClientIO $ do
    conn <- newHttp2FrameConnection host port (tlsSettings False host port)
    runHttp2Client conn 8192 8192 [] defaultGoAwayHandler ignoreFallbackHandler $ \client -> do
      liftIO $ putStrLn "~~~connected~~~"
      let ifc = _incomingFlowControl client
      let ofc = _outgoingFlowControl client
      liftIO $ _addCredit ifc 10000000
      _ <- _updateWindow ifc
      reply <- open client "grpcb.in:9000" [] (Timeout 100) encoding decoding
        (singleRequest (RPC :: RPC GRPCBin "specificError") (defMessage & code .~ 1 & reason .~ "kikoo"))

      liftIO $ print reply
