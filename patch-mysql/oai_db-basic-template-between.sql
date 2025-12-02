

-- --------------------------------------------------------

--
-- Table structure for table `SdmSubscriptions`
--

CREATE TABLE `SdmSubscriptions` (
  `ueid` varchar(15) NOT NULL,
  `subsId` int(10) UNSIGNED NOT NULL,
  `nfInstanceId` varchar(50) NOT NULL,
  `implicitUnsubscribe` tinyint(1) DEFAULT NULL,
  `expires` varchar(50) DEFAULT NULL,
  `callbackReference` varchar(50) NOT NULL,
  `amfServiceName` json DEFAULT NULL,
  `monitoredResourceUris` json NOT NULL,
  `singleNssai` json DEFAULT NULL,
  `dnn` varchar(50) DEFAULT NULL,
  `subscriptionId` varchar(50) DEFAULT NULL,
  `plmnId` json DEFAULT NULL,
  `immediateReport` tinyint(1) DEFAULT NULL,
  `report` json DEFAULT NULL,
  `supportedFeatures` varchar(50) DEFAULT NULL,
  `contextInfo` json DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `SessionManagementSubscriptionData`
--

CREATE TABLE `SessionManagementSubscriptionData` (
  `ueid` varchar(15) NOT NULL,
  `servingPlmnid` varchar(15) NOT NULL,
  `singleNssai` json NOT NULL,
  `dnnConfigurations` json DEFAULT NULL,
  `internalGroupIds` json DEFAULT NULL,
  `sharedVnGroupDataIds` json DEFAULT NULL,
  `sharedDnnConfigurationsId` varchar(50) DEFAULT NULL,
  `odbPacketServices` json DEFAULT NULL,
  `traceData` json DEFAULT NULL,
  `sharedTraceDataId` varchar(50) DEFAULT NULL,
  `expectedUeBehavioursList` json DEFAULT NULL,
  `suggestedPacketNumDlList` json DEFAULT NULL,
  `3gppChargingCharacteristics` varchar(50) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `SmfRegistrations`
--

CREATE TABLE `SmfRegistrations` (
  `ueid` varchar(15) NOT NULL,
  `subpduSessionId` int(10) NOT NULL,
  `smfInstanceId` varchar(50) NOT NULL,
  `smfSetId` varchar(50) DEFAULT NULL,
  `supportedFeatures` varchar(50) DEFAULT NULL,
  `pduSessionId` int(10) NOT NULL,
  `singleNssai` json NOT NULL,
  `dnn` varchar(50) DEFAULT NULL,
  `emergencyServices` tinyint(1) DEFAULT NULL,
  `pcscfRestorationCallbackUri` varchar(50) DEFAULT NULL,
  `plmnId` json NOT NULL,
  `pgwFqdn` varchar(50) DEFAULT NULL,
  `epdgInd` tinyint(1) DEFAULT NULL,
  `deregCallbackUri` varchar(50) DEFAULT NULL,
  `registrationReason` json DEFAULT NULL,
  `registrationTime` varchar(50) DEFAULT NULL,
  `contextInfo` json DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `SmfSelectionSubscriptionData`
--

CREATE TABLE `SmfSelectionSubscriptionData` (
  `ueid` varchar(15) NOT NULL,
  `servingPlmnid` varchar(15) NOT NULL,
  `supportedFeatures` varchar(50) DEFAULT NULL,
  `subscribedSnssaiInfos` json DEFAULT NULL,
  `sharedSnssaiInfosId` varchar(50) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `AccessAndMobilitySubscriptionData`
--
ALTER TABLE `AccessAndMobilitySubscriptionData`
  ADD PRIMARY KEY (`ueid`,`servingPlmnid`) USING BTREE;

--
-- Indexes for table `Amf3GppAccessRegistration`
--
ALTER TABLE `Amf3GppAccessRegistration`
  ADD PRIMARY KEY (`ueid`);

--
-- Indexes for table `AuthenticationStatus`
--
ALTER TABLE `AuthenticationStatus`
  ADD PRIMARY KEY (`ueid`);

--
-- Indexes for table `AuthenticationSubscription`
--
ALTER TABLE `AuthenticationSubscription`
  ADD PRIMARY KEY (`ueid`);

--
-- Indexes for table `SdmSubscriptions`
--
ALTER TABLE `SdmSubscriptions`
  ADD PRIMARY KEY (`subsId`,`ueid`) USING BTREE;

--
-- Indexes for table `SessionManagementSubscriptionData`
--
ALTER TABLE `SessionManagementSubscriptionData`
  ADD PRIMARY KEY (`ueid`,`servingPlmnid`) USING BTREE;

--
-- Indexes for table `SmfRegistrations`
--
ALTER TABLE `SmfRegistrations`
  ADD PRIMARY KEY (`ueid`,`subpduSessionId`) USING BTREE;

--
-- Indexes for table `SmfSelectionSubscriptionData`
--
ALTER TABLE `SmfSelectionSubscriptionData`
  ADD PRIMARY KEY (`ueid`,`servingPlmnid`) USING BTREE;

--
-- AUTO_INCREMENT for dumped tables
--
-- Dynamic IPADDRESS Allocation
