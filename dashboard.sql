-- MySQL dump 10.16  Distrib 10.2.19-MariaDB, for Linux (x86_64)
--
-- Host: localhost    Database: dashboard
-- ------------------------------------------------------
-- Server version	10.2.19-MariaDB

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `disk`
--

DROP TABLE IF EXISTS `disk`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `disk` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `lparname` varchar(50) NOT NULL,
  `disk` varchar(10) NOT NULL,
  `rw_timeout` int(11) NOT NULL,
  `queue_depth` int(11) NOT NULL,
  `algorithm` varchar(50) NOT NULL,
  `timeout_policy` varchar(50) NOT NULL,
  `reserve_policy` varchar(50) NOT NULL,
  `dist_tw_width` int(11) NOT NULL,
  `dist_err_pcnt` int(11) NOT NULL,
  `hcheck_interval` int(11) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=111573 DEFAULT CHARSET=ascii;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `fcs`
--

DROP TABLE IF EXISTS `fcs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `fcs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `lparname` varchar(50) NOT NULL,
  `adapter` varchar(10) NOT NULL,
  `max_xfer_size` varchar(20) NOT NULL,
  `num_cmd_elems` int(11) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2493 DEFAULT CHARSET=ascii;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `fscsi`
--

DROP TABLE IF EXISTS `fscsi`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `fscsi` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `lparname` varchar(50) NOT NULL,
  `adapter` varchar(10) NOT NULL,
  `fc_err_recov` varchar(20) NOT NULL,
  `dyntrk` varchar(8) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4157 DEFAULT CHARSET=ascii;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `ieee`
--

DROP TABLE IF EXISTS `ieee`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `ieee` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `lparname` varchar(50) NOT NULL,
  `adapter` varchar(10) NOT NULL,
  `hash_mode` varchar(50) NOT NULL,
  `s_interval` varchar(20) NOT NULL,
  `mode` varchar(20) NOT NULL,
  `jumbo_frames` varchar(10) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=1448 DEFAULT CHARSET=ascii;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `lpm`
--

DROP TABLE IF EXISTS `lpm`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `lpm` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `lparname` varchar(50) NOT NULL,
  `status` int(1) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=773 DEFAULT CHARSET=ascii;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `memory`
--

DROP TABLE IF EXISTS `memory`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `memory` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `lparname` varchar(50) NOT NULL,
  `memorysize` int(11) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=773 DEFAULT CHARSET=ascii;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `phys_eth`
--

DROP TABLE IF EXISTS `phys_eth`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `phys_eth` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `lparname` varchar(50) NOT NULL,
  `ent` varchar(5) NOT NULL,
  `checksum_offload` varchar(5) NOT NULL,
  `jumbo_frames` varchar(5) NOT NULL,
  `flow_ctrl` varchar(5) NOT NULL,
  `large_receive` varchar(5) NOT NULL,
  `largesend` varchar(5) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=5664 DEFAULT CHARSET=ascii;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `sea`
--

DROP TABLE IF EXISTS `sea`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `sea` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `lparname` varchar(50) NOT NULL,
  `ent` varchar(10) NOT NULL,
  `largesend` int(1) NOT NULL,
  `large_receive` varchar(5) NOT NULL,
  `jumbo_frames` varchar(5) NOT NULL,
  `adapter_reset` varchar(5) NOT NULL,
  `accounting` varchar(15) NOT NULL,
  `ha_mode` varchar(20) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2161 DEFAULT CHARSET=ascii;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `swap`
--

DROP TABLE IF EXISTS `swap`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `swap` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `lparname` varchar(50) NOT NULL,
  `swapsize` int(11) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=773 DEFAULT CHARSET=ascii;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `veth`
--

DROP TABLE IF EXISTS `veth`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `veth` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `lparname` varchar(50) NOT NULL,
  `adapter` varchar(8) NOT NULL,
  `mtu_bypass` varchar(5) NOT NULL,
  `rfc1323` int(11) NOT NULL,
  `tcp_sendspace` int(11) NOT NULL,
  `tcp_recvspace` int(11) NOT NULL,
  `udp_recvspace` int(11) NOT NULL,
  `udp_sendspace` int(11) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=1548 DEFAULT CHARSET=ascii;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `veth_buf`
--

DROP TABLE IF EXISTS `veth_buf`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `veth_buf` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `lparname` varchar(50) NOT NULL,
  `adapter` varchar(10) NOT NULL,
  `min_buf_tiny` int(11) NOT NULL,
  `max_buf_tiny` int(11) NOT NULL,
  `min_buf_small` int(11) NOT NULL,
  `max_buf_small` int(11) NOT NULL,
  `min_buf_medium` int(11) NOT NULL,
  `max_buf_medium` int(11) NOT NULL,
  `min_buf_large` int(11) NOT NULL,
  `max_buf_large` int(11) NOT NULL,
  `min_buf_huge` int(11) NOT NULL,
  `max_buf_huge` int(11) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=18599 DEFAULT CHARSET=ascii;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2018-12-21 15:47:34
