# -*- Mode:python; c-file-style:"gnu"; indent-tabs-mode:nil -*- */

import sys
import time
import argparse
import traceback

from pyndn import Interest
from pyndn import Name
from pyndn import Face


class Consumer(object):

    def __init__(self, prefix):
        # Create a connection to the local forwarder and
        # initialize outstanding Interest state keeping
        pass


    def run(self):
        # Send Interest and run event loop until
        # we receive a response or exceed retry attempts.
        pass


    def _sendNextInterest(self, name):
        # Create an Interest using incoming name
        # and record it in our outstanding Interest.
        # Then, send the Interest out our Face.
        pass


    def _onData(self, interest, data):
        # Print the Data's payload and remove
        # the associated Interest from the outstanding table.
        # Finally, signal the event loop that we are finished.
        pass


    def _onTimeout(self, interest):
        # Increment the retry count and resend the Interest
        # if we have not exceeded the maximum number of retries.
        pass





if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Parse command line args for ndn consumer')
    parser.add_argument("-u", "--uri", required=True, help='ndn name to retrieve')

    args = parser.parse_args()

    try:
        uri = args.uri
        Consumer(uri).run()

    except:
        traceback.print_exc(file=sys.stdout)
        print "Error parsing command line arguments"
        sys.exit(1)
