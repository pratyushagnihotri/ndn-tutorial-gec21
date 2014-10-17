### Extended Hello World

With the basics of NDN application writing in PyNDN2 covered, we can
now extend the producer and consumer into more useful NDN
applications. Specifically, you'll learn how to:

* Serve pre-generated content
* Communicate the end of a sequence or stream of content to consumers
* Retrieve content that spans multiple Data packets
* Pipeline multiple Interests

For this section, we will reuse the previous topology scenario after
enhancing the producer and consumers.

#### Extended Producer

The extended `Producer` class pre-packetizes its content and stores it
to make it easy to serve subsequent requests. Typically, an
application will publish content that is larger than the maximum
packet size (currently about 8 KB). This makes it necessary for the
publisher to *sequence* the Data packets so that consumers can
recognize when there is more content to be retrieved.

* Extend `Producer`'s constructor.

In NDN, packet sequence numbers can be presented in name components by
the `0x00` marker followed by the number (see the [NDN Naming Conventions](http://named-data.net/wp-content/uploads/2014/08/ndn-tr-22-ndn-memo-naming-conventions.pdf) memo for more details). We can see this in action in the extended `Producer`'s constructor.

    class Producer(object):

      def __init__(self, prefix, maxCount=1):
          self.keyChain = KeyChain()
          self.prefix = Name(prefix)
          self.isDone = False

          # Initialize list for Data packet storage.
          # We'll treat the indices as equivalent to the sequence
          # number requested by Interests.
          self.data = []

          finalBlock = Name.Component.fromNumberWithMarker(maxCount - 1, 0x00)
          hourMilliseconds = 3600 * 1000

          # Pre-generate and sign all of Data we can serve.
          # We can also set the FinalBlockID in each packet
          # ahead of time because we know the entire sequence.

          for i in range(maxCount):
              dataName = Name(prefix).appendSegment(i)

              data = Data(dataName)
              data.setContent("Hello, " + dataName.toUri())
              data.getMetaInfo().setFinalBlockID(finalBlock)
              data.getMetaInfo().setFreshnessPeriod(hourMilliseconds)

              self.keyChain.sign(data, self.keyChain.getDefaultCertificateName())

              self.data.append(data)


We initialize a list to store the Data packets we create. For the sake
of this example, we'll generate a pre-determined number of packets
specified by `maxCount`. In a real application, such as serving a
large file, `maxCount` could instead be calculated based on the
desired Data packet size.

Knowing the number of packets to generate ahead of time or that are
remaining allows us to inform the consumer of the end of the content
sequence. Producers can inform their consumers of the end by setting the
FinalBlockId meta-information in one or more of the Data packets. The
optional FinalBlockId field is an NDN name component found in the
Data's MetaInfo TLV block (i.e. not in the Data's Name TLV). Consumers
determine whether a given Data packet is the last one in a sequence by
comparing the FinalBlockId to the last component (before the implicit
digest) of the Data's name. If the fields match, then the Data packet
is the last item in the sequence. One common use is for the
FinalBlockId to refer to a sequence number name component, but any
valid name component can signal the end of a collection.

* Modify the event loop method.

    def run(self):
        face = Face()

        # Use the system default key chain and certificate name to sign commands.
        face.setCommandSigningInfo(self.keyChain, self.keyChain.getDefaultCertificateName())

        # Also use the default certificate name to sign data packets.
        face.registerPrefix(self.prefix, self.onInterest, self.onRegisterFailed)

        print "Registering prefix %s" % self.prefix.toUri()

        while not self.isDone:
            face.processEvents()
            time.sleep(0.01)


`run` no longer needs a namespace argument because we already know the
prefix and have constructed all of the Data packets in the
constructor.

* Modify `onInterest` to serve Data out of the pre-constructed packet set.

<!-- -->

    def onInterest(self, prefix, interest, transport, registeredPrefixId):
        interestName = interest.getName()
        sequence = interestName[-1].toNumber()

        if 0 <= sequence and sequence < len(self.data):
            transport.send(self.data[sequence].wireEncode().toBuffer())

        print "Replied to: %s" % interestName.toUri()

`onInterest` determines the correct Data packet to publish by
converting the incoming Interest's sequence number to a list index.

* Expose the static dataset functionality in the script's `__main__` block.

Add a *count* option to the command line parser that tells the
producer how many Data packets to prepare.

    if __name__ == '__main__':
        parser = argparse.ArgumentParser(description='Parse command line args for ndn producer')
        parser.add_argument("-n", "--namespace", required=True, help='namespace to listen under')
        parser.add_argument("-c", "--count", required=False, help='number of Data packets to generate, default = 1', nargs='?', const=1,  type=int, default=1)

        args = parser.parse_args()

        try:
            namespace = args.namespace
            maxCount = args.count

            Producer(namespace, maxCount).run()

        except:
            traceback.print_exc(file=sys.stdout)
            sys.exit(1)


#### Extended Consumer

We can now extend our initial `Consumer` class to fully use the
enhanced `Producer`. First, `Consumer` must be able to request the
entire range of published content. Second, `Consumer` should be able
to request *multiple* Data packets at once by pipelining the
Interests. While `Consumer` could wait for each requested Data to
return before requesting another item, the process is much slower than
requesting multiple items simultaneously.

* Extend `Consumer`'s constructor.
  * Keep track of the next Data segment to request.
  * Accept a pipeline size to determine the number of inflight
    Interests to maintain.

    class Consumer(object):
        def __init__(self, prefix, pipeline):
            self.prefix = Name(prefix)
            self.pipeline = pipeline
            self.nextSegment = 0
            self.outstanding = dict()
            self.isDone = False
            self.face = Face("127.0.0.1")



* Modify `run` to maintain the Interest pipeline.

<!-- -->

    def run(self):
        try:
            while self.nextSegment < self.pipeline:
                self._sendNextInterest(self.prefix)
                self.nextSegment += 1

            while not self.isDone:
                self.face.processEvents()
                time.sleep(0.01)

        except RuntimeError as e:
            print "ERROR: %s" %  e


`run` immediately sends `self.pipeline` count Interests. As each
Interest returns Data (or expires), a new Interest will be sent in its
place for the next segment (or retransmission). This process repeats
until the entire collection has been retrieved.


* Refactor Interest sending to handle retransmission of earlier segments.

<!-- -->

    def _sendNextInterest(self, name):
        nameWithSegment = Name(name).appendSegment(self.nextSegment)
        self._sendNextInterestWithSegment(nameWithSegment)


    def _sendNextInterestWithSegment(self, name):
        interest = Interest(name)
        uri = name.toUri()

        interest.setInterestLifetimeMilliseconds(4000)
        interest.setMustBeFresh(True)

        if uri not in self.outstanding:
            self.outstanding[uri] = 1

        self.face.expressInterest(interest, self._onData, self._onTimeout)
        print "Sent Interest for %s" % uri

It is now possible that we either need to request the latest segment
or retransmit any one of the previously pipelined
Interests. `_sendNextInterest` has been refactored into a frontend for
sending an Interest with the latest sequence number. The actual
Interest sending moves into `_sendNextInterestWithSegment`, that
expects a `Name` instance with the appropriate sequence number
appended.


* Modify `_onData` to look for the last Data segment.

<!-- -->

    def _onData(self, interest, data):
        payload = data.getContent()
        dataName = data.getName()

        print "Received data: ", payload.toRawStr()
        del self.outstanding[interest.getName().toUri()]

        finalBlockId = data.getMetaInfo().getFinalBlockID()

        if finalBlockId.getValue().size() > 0 and \
           finalBlockId == dataName[-1]:
            self.isDone = True
        else:
            self._sendNextInterest(self.prefix)
            self.nextSegment += 1

`_onData` now checks if the arrived Data packet is the final block of the collection and starts the program termination process if it is.

A Data packet's FinalBlockId is accessed, much like it is set, via a
meta-information object. Before checking the value of the
FinalBlockId, it is first necessary to ensure that the field is
actually present; `data.getMetaInfo().getFinalBlockID()` will not
produce an error if the field is absent. Instead, the application must
check to see if the FinalBlockId field has a non-zero length. If a
value is present, it can be interpreted as a `Name.Component`
instance. We can then compare the FinalBlockId directly against the
Data's name component preceding the implicit digest (i.e. the -1 with
PyNDN2's negative index support).

* Modify timeout handling to support retrying earlier segments.

<!-- -->

    def _onTimeout(self, interest):
        name = interest.getName()
        uri = name.toUri()

        print "TIMEOUT #%d: segment #%s" % (self.outstanding[uri], name[-1].toNumber())
        self.outstanding[uri] += 1

        if self.outstanding[uri] <= 3:
            self._sendNextInterestWithSegment(name)
        else:
            self.isDone = True

`Consumer._onTimeout` now uses`Consumer._sendNextInterestWithSegment`
to retransmit an Interest with a specific sequence number.

* Expose Interest pipelining in the script's `__main__` block.

Extend the commandline argument parser to accept a pipeline parameter and pass its value to Consumer's constructor.

    if __name__ == "__main__":
        parser = argparse.ArgumentParser(description='Parse command line args for ndn consumer')

        parser.add_argument("-u", "--uri", required=True, help='ndn URI to retrieve')
        parser.add_argument("-p", "--pipe",required=False, help='number of Interests to pipeline, default = 1', nargs= '?', const=1, type=int, default=1)

        args = parser.parse_args()

        try:
            uri = args.uri
            pipeline = args.pipe

            Consumer(uri, pipeline).run()

        except:
            traceback.print_exc(file=sys.stdout)
            print "Error parsing command line arguments"
            sys.exit(1)


#### Running the Extended Hello World Application Scenario

With the producer and consumer extended, let's re-run the the UCLA to
CSU scenario.

* Copy the extended consumer application to UCLA-1 and UCLA-2.
* Copy the extended producer to CSU-1.
* (Re)start the NFD instance on each node and configure routing  by
running the `tools/setup-app.sh` on your local machine.
  * **Windows:** SSH into each node and run the following commands instead of using `tools/setup-app.sh`:

<!-- -->

    nfd-stop; sleep 2; nfd-start;
    sh /usr/local/bin/setup-app-remote.sh

* SSH into CSU-1 and start the producer:

<!-- -->

    python hello_producer.py -n /csu/hello -c 10

* SSH into UCLA-1 and UCLA-2 and run one consumer on each:

<!-- -->

    python hello_consumer.py -u /csu/hello -p 2

You should see each consumer print messages indicating that they
successfully pulled all of the content. The producer should show that
it serves each distinct Data packet once.

## Weighted Load Balancer

While a good demonstration of the basic principles of creating a
forwarding strategy, our stateless `RandomLoadBalancerStrategy` is
probably too simple for many real world use cases. Instead, you may
want to create a strategy that stores and acts on some kind of
measurement information. NFD provides an interface for
attaching information to existing constructs such as PIT entries and a
Measurements table for this purpose.

For our next custom strategy, we will take advantage of these storage
options to keep track of performance information. The
`WeightedLoadBalancerStrategy` will time how long it takes to receive
a Data response for each Face it sends an Interest out and will bias
future forwarding towards Faces with faster responses. To do this,
`WeightedLoadBalancerStrategy` will record the time it sends an Interest
on the PIT entry.

However, the strategy will also need to remember the last retrieval
delay for each Face. Therefore, it needs a place to store the delay
collection where it can be easily retrieved and *persist* across
Interests (after all, the PIT entry will be consumed). NFD's
Measurement table is such a storage option.

To begin, we'll name the new strategy
`ndn:/localhost/nfd/strategy/weighted-load-balancer`:

    const Name WeightedLoadBalancerStrategy::STRATEGY_NAME("ndn:/localhost/nfd/strategy/weighted-load-balancer");

Next, before digging into the implementation of the strategy itself,
we'll define two custom storage classes to hold our clock and delay
measurements. The only requirement for custom storage classes is that
they extend the `StrategyInfo` class; NFD will not attempt to modify
the data itself in anyway, but will garbage collect old Measurement
table data.

    class MyPitInfo : public StrategyInfo
    {
    public:
        MyPitInfo()
            : creationTime(system_clock::now())
        {}

        system_clock::TimePoint creationTime;
    };


    class MyMeasurementInfo : public StrategyInfo
    {
    public:
        void
        updateFaceDelay(const Face& face, const milliseconds& delay);

        void
        updateStoredNextHops(const fib::NextHopList& nexthops);

        static milliseconds
        calculateInverseDelaySum(const shared_ptr<MyMeasurementInfo>& info);
            ...

        //Collection of Faces sorted by delay
        WeightedFaceSet weightedFaces;
    };


`MyPitInfo` records the time the instance was created at
(i.e. starting a timer). `MyMeasurementInfo` holds the delay
collection (sorted by increasing delay) and provides helpers to
manipulate the set.

With the storage classes defined, we can now override the `Strategy`
class' methods. First, we will override `afterReceiveInterest` to
record Interest send times by creating and storing `MyPitInfo`
instances. The delay biasing calculations and housekeeping are
implemented in other methods that are omitted for brevity.

    void
    WeightedLoadBalancerStrategy::afterReceiveInterest(const Face& inFace,
                                                       const Interest& interest,
                                                       shared_ptr<fib::Entry> fibEntry,
                                                       shared_ptr<pit::Entry> pitEntry)
    {
      // not a new Interest, don't forward
      if (pitEntry->hasUnexpiredOutRecords())
        return;

      // create timer information and attach to PIT entry
      pitEntry->setStrategyInfo<MyPitInfo>(make_shared<MyPitInfo>());

      shared_ptr<MyMeasurementInfo> measurementsEntryInfo =
               myGetOrCreateMyMeasurementInfo(fibEntry);


      // reconcile differences between incoming nexthops and those stored
      // on our custom measurement entry info
      measurementsEntryInfo->updateStoredNextHops(fibEntry->getNextHops());

      if (!this->mySendInterest(interest, measurementsEntryInfo, pitEntry))
        {
          this->rejectPendingInterest(pitEntry);
          BOOST_ASSERT(false);
        }
    }

The first important line in the above code is

    pitEntry->setStrategyInfo<MyPitInfo>(make_shared<MyPitInfo>());

which creates a new `MyPitInfo` instance (our send time storage) and
attaches it to the PIT entry.

Next, our strategy needs to access its previously stored delay
measurements to determine where it should send the current
Interest. For this, the strategy needs to access the Measurements
table. Measurements table entries are associated with name prefixes
just like any other (FIB, PIT, etc.)  NFD table. Here, we have a
helper method that will lookup and retrieve the Measurements table
entry using the FIB entry's prefix (i.e. stored at the same level of
the tree).

    shared_ptr<MyMeasurementInfo>
    WeightedLoadBalancerStrategy::myGetOrCreateMyMeasurementInfo(const shared_ptr<fib::Entry>& entry)
    {
      BOOST_ASSERT(static_cast<bool>(entry));

      shared_ptr<measurements::Entry> measurementsEntry =
        this->getMeasurements().get(*entry);

      shared_ptr<MyMeasurementInfo> measurementsEntryInfo =
        measurementsEntry->getStrategyInfo<MyMeasurementInfo>();

      if (!static_cast<bool>(measurementsEntryInfo))
        {
          measurementsEntryInfo = make_shared<MyMeasurementInfo>();
          measurementsEntry->setStrategyInfo(measurementsEntryInfo);
        }

      return measurementsEntryInfo;
    }

Access to Measurement table entries is restricted to the forwarding
strategy that is assigned for that prefix. NFD provides access control
via the `MeasurementsAccessor` class. All attempts to retrieve
Measurement entries must go through this access (acquired in the above
code via `Strategy::getMeasurements()`). This caveat aside, accessing
and storing information on Measurement entries is identical to PIT
entries with the use of the `get/setStrategyInfo` methods. The rest of
the surround code creates a new instance of our custom delay storage
class if one was not already present.


With the Interest clock started and access to our delay measurements
for sending, we now look to actually recording the delay
measurements. To do this, we need to stop the clock when the Data
packet arrives. NFD will notify our strategy when Data arrives before
satisfying the corresponding PIT entry. The strategy's
`beforeSatisfyPendingInterest` method will be invoked once for each PIT entry
that is consumed with the PIT entry, the Face the Data is arrived
over, and the Data itself. We can access the information
stored on the PIT entry by calling `pit::Entry::getStrategyInfo<T>()`
(where `T` is the custom information type, `MyPitInfo` here).

    void
    WeightedLoadBalancerStrategy::beforeSatisfyPendingInterest(shared_ptr<pit::Entry> pitEntry,
                                                               const Face& inFace,
                                                               const Data& data)
    {
      shared_ptr<MyPitInfo> pitInfo = pitEntry->getStrategyInfo<MyPitInfo>();

      // No start time available, cannot compute delay for this retrieval
      if (!static_cast<bool>(pitInfo))
        return;

      const milliseconds delay =
        duration_cast<milliseconds>(system_clock::now() - pitInfo->creationTime);

      MeasurementsAccessor& accessor = this->getMeasurements();

      // Update Face delay measurements and entry lifetimes owned
      // by this strategy while walking up the NameTree
      shared_ptr<measurements::Entry> measurementsEntry = accessor.get(*pitEntry);
      while (static_cast<bool>(measurementsEntry))
        {
          shared_ptr<MyMeasurementInfo> measurementsEntryInfo =
            measurementsEntry->getStrategyInfo<MyMeasurementInfo>();

          if (static_cast<bool>(measurementsEntryInfo))
            {
              accessor.extendLifetime(measurementsEntry, seconds(16));
              measurementsEntryInfo->updateFaceDelay(inFace, delay);
            }

          measurementsEntry = accessor.getParent(measurementsEntry);
        }
    }

The most complicated part of this `beforeSatisfyPendingInterest`
implementation is the recording of delay information. Previously, we
saw how to use a `MeasurementsAccessor` to fetch/create/set
information on a Measurement entry. The above code will also set the
entry's information, but there's one problem: which entry?

Before, we accessed the Measurement table through the use of the FIB
entry's prefix. In `beforeSatisfyPendingInterest` we only have the PIT
entry in hand and that may be *more specific* (i.e. longer) than the
FIB entry we will use when it comes time to send an
Interest. Therefore, it is necessary to update the chain of
Measurement entries with the new information. The entry tree is walked
here in the trailing while loop by using
`MeasurementsAccessor::getParent` method.

We also take this opportunity to refresh the lifetime of our custom
information. Measurement entry information periodically expires and is
garbage collected. We can prevent this from happening by asking
NFD to extend the information's lifetime through the accessor:

    accessor.extendLifetime(measurementsEntry, seconds(16));

Together, `beforeSatisfyPendingInterest` and `afterReceiveInterest`
make up the core of forwarding strategies; everything else is
implementation specific. We have also seen how to store and retrieve
custom information on NFD constructs. You are encouraged to refer to
the
[NFD Developer's Guide](http://named-data.net/wp-content/uploads/2014/07/NFD-developer-guide.pdf)
for more information of storing useful items and additional attachment
points.

## Installing and Running the Weighted Load Balancer Forwarding Strategy Scenario

![Weighted load balancer strategy topology](img/weighted-strategy-scenario.png)

The finished forwarding strategy
(`weighted-load-balancer-strategy.{cpp,hpp}`) can now be compiled as
part of the normal NFD build process. Again, copy your completed
strategy source files to `/usr/local/src/NFD/daemon/fw/` on the
UCLA-HUB node. Next, SSH into UCLA-HUB and edit
`/usr/local/src/NFD/daemon/fw/available-strategies.cpp` C++ source
file's `installStrategies` method to include:

        void
        installStrategies(Forwarder& forwarder)
        {
            ...

          // Add strategy to be installed
          installStrategy<WeightedLoadBalancerStrategy>(forwarder);
        }

Compile and re-install NFD:

    cd /usr/local/src/NFD
    sudo ./waf
    sudo ./waf install

Finally, (re)start the NFD instance on each node by running the
`tools/setup-app.sh` on your local machine.

**NOTE:** If you cannot execute shell scripts, you will need to SSH into each node and run the following commands to restart NFD and setup routing:

    nfd-stop; sleep 2; nfd-start;
    sh /usr/local/bin/setup-strategy-remote.sh weighted

Like the previous random load balancer scenario, UCLA-1 and UCLA-2
will act as producers and CSU-1 will be the consumer. UCLA-HUB, which
you installed the forwarding strategy on, will load balance requests
across the producers.

Once again, try using the provided `tools/producer.py` and
`tools/consumer.py`.  Add a 2 second delay to one producer and have
the consumer request 100 packets. Note how much faster the consumer
finishes retrieving the same number of packets.
