-- phpMyAdmin SQL Dump
-- version 5.1.0
-- https://www.phpmyadmin.net/
--
-- Host: 172.16.200.10:3306
-- Generation Time: Mar 22, 2021 at 10:31 AM
-- Server version: 5.7.33
-- PHP Version: 7.4.15

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `oai_db`
--

-- --------------------------------------------------------

--
-- Table structure for table `AccessAndMobilitySubscriptionData`
--

CREATE TABLE `AccessAndMobilitySubscriptionData` (
  `ueid` varchar(15) NOT NULL,
  `servingPlmnid` varchar(15) NOT NULL,
  `supportedFeatures` varchar(50) DEFAULT NULL,
  `gpsis` json DEFAULT NULL,
  `internalGroupIds` json DEFAULT NULL,
  `sharedVnGroupDataIds` json DEFAULT NULL,
  `subscribedUeAmbr` json DEFAULT NULL,
  `nssai` json DEFAULT NULL,
  `ratRestrictions` json DEFAULT NULL,
  `forbiddenAreas` json DEFAULT NULL,
  `serviceAreaRestriction` json DEFAULT NULL,
  `coreNetworkTypeRestrictions` json DEFAULT NULL,
  `rfspIndex` int(10) DEFAULT NULL,
  `subsRegTimer` int(10) DEFAULT NULL,
  `ueUsageType` int(10) DEFAULT NULL,
  `mpsPriority` tinyint(1) DEFAULT NULL,
  `mcsPriority` tinyint(1) DEFAULT NULL,
  `activeTime` int(10) DEFAULT NULL,
  `sorInfo` json DEFAULT NULL,
  `sorInfoExpectInd` tinyint(1) DEFAULT NULL,
  `sorafRetrieval` tinyint(1) DEFAULT NULL,
  `sorUpdateIndicatorList` json DEFAULT NULL,
  `upuInfo` json DEFAULT NULL,
  `micoAllowed` tinyint(1) DEFAULT NULL,
  `sharedAmDataIds` json DEFAULT NULL,
  `odbPacketServices` json DEFAULT NULL,
  `serviceGapTime` int(10) DEFAULT NULL,
  `mdtUserConsent` json DEFAULT NULL,
  `mdtConfiguration` json DEFAULT NULL,
  `traceData` json DEFAULT NULL,
  `cagData` json DEFAULT NULL,
  `stnSr` varchar(50) DEFAULT NULL,
  `cMsisdn` varchar(50) DEFAULT NULL,
  `nbIoTUePriority` int(10) DEFAULT NULL,
  `nssaiInclusionAllowed` tinyint(1) DEFAULT NULL,
  `rgWirelineCharacteristics` varchar(50) DEFAULT NULL,
  `ecRestrictionDataWb` json DEFAULT NULL,
  `ecRestrictionDataNb` tinyint(1) DEFAULT NULL,
  `expectedUeBehaviourList` json DEFAULT NULL,
  `primaryRatRestrictions` json DEFAULT NULL,
  `secondaryRatRestrictions` json DEFAULT NULL,
  `edrxParametersList` json DEFAULT NULL,
  `ptwParametersList` json DEFAULT NULL,
  `iabOperationAllowed` tinyint(1) DEFAULT NULL,
  `wirelineForbiddenAreas` json DEFAULT NULL,
  `wirelineServiceAreaRestriction` json DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `Amf3GppAccessRegistration`
--

CREATE TABLE `Amf3GppAccessRegistration` (
  `ueid` varchar(15) NOT NULL,
  `amfInstanceId` varchar(50) NOT NULL,
  `supportedFeatures` varchar(50) DEFAULT NULL,
  `purgeFlag` tinyint(1) DEFAULT NULL,
  `pei` varchar(50) DEFAULT NULL,
  `imsVoPs` json DEFAULT NULL,
  `deregCallbackUri` varchar(50) NOT NULL,
  `amfServiceNameDereg` json DEFAULT NULL,
  `pcscfRestorationCallbackUri` varchar(50) DEFAULT NULL,
  `amfServiceNamePcscfRest` json DEFAULT NULL,
  `initialRegistrationInd` tinyint(1) DEFAULT NULL,
  `guami` json NOT NULL,
  `backupAmfInfo` json DEFAULT NULL,
  `drFlag` tinyint(1) DEFAULT NULL,
  `ratType` json NOT NULL,
  `urrpIndicator` tinyint(1) DEFAULT NULL,
  `amfEeSubscriptionId` varchar(50) DEFAULT NULL,
  `epsInterworkingInfo` json DEFAULT NULL,
  `ueSrvccCapability` tinyint(1) DEFAULT NULL,
  `registrationTime` varchar(50) DEFAULT NULL,
  `vgmlcAddress` json DEFAULT NULL,
  `contextInfo` json DEFAULT NULL,
  `noEeSubscriptionInd` tinyint(1) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `AuthenticationStatus`
--

CREATE TABLE `AuthenticationStatus` (
  `ueid` varchar(20) NOT NULL,
  `nfInstanceId` varchar(50) NOT NULL,
  `success` tinyint(1) NOT NULL,
  `timeStamp` varchar(50) NOT NULL,
  `authType` varchar(25) NOT NULL,
  `servingNetworkName` varchar(50) NOT NULL,
  `authRemovalInd` tinyint(1) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `AuthenticationSubscription`
--

CREATE TABLE `AuthenticationSubscription` (
  `ueid` varchar(20) NOT NULL,
  `authenticationMethod` varchar(25) NOT NULL,
  `encPermanentKey` varchar(50) DEFAULT NULL,
  `protectionParameterId` varchar(50) DEFAULT NULL,
  `sequenceNumber` json DEFAULT NULL,
  `authenticationManagementField` varchar(50) DEFAULT NULL,
  `algorithmId` varchar(50) DEFAULT NULL,
  `encOpcKey` varchar(50) DEFAULT NULL,
  `encTopcKey` varchar(50) DEFAULT NULL,
  `vectorGenerationInHss` tinyint(1) DEFAULT NULL,
  `n5gcAuthMethod` varchar(15) DEFAULT NULL,
  `rgAuthenticationInd` tinyint(1) DEFAULT NULL,
  `supi` varchar(20) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Dumping data for table `AuthenticationSubscription`
--

