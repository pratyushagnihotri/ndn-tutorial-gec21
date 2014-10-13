# -*- Mode:python; c-file-style:"gnu"; indent-tabs-mode:nil -*- */

import sys
import time
import argparse
import traceback
import random

from pyndn import Name
from pyndn import Data
from pyndn import Face
from pyndn.security import KeyChain


class Producer(object):

    def __init__(self):
        # Initialize our keychain
        pass


    def run(self, namespace):
        # Create a connection to the local forwarder.
        # Use the system default key chain and certificate name to sign commands.
        # Also use the default certificate name to sign Data packets.


        # Run the event loop forever. Use a short sleep to
        # prevent the Producer from using 100% of the CPU.
        pass



    def onInterest(self, prefix, interest, transport, registeredPrefixId):
        # Create a response Data packet with the same name as
        # the incoming Interest.
        # Then, sign the Data with our keychain and send it out
        # using transport.
        pass


    def onRegisterFailed(self, prefix):
        # Print an error message and signal the event loop to terminate
        pass






if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Parse command line args for ndn producer')
    parser.add_argument("-n", "--namespace", required=True, help='namespace to listen under')

    args = parser.parse_args()

    try:
        namespace = args.namespace
        Producer().run(namespace)

    except:
        traceback.print_exc(file=sys.stdout)
        sys.exit(1)
