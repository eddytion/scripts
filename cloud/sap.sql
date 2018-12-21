-- MySQL dump 10.16  Distrib 10.2.19-MariaDB, for Linux (x86_64)
--
-- Host: localhost    Database: sap
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
-- Table structure for table `buildsheet`
--

DROP TABLE IF EXISTS `buildsheet`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `buildsheet` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `product_name` longtext DEFAULT NULL,
  `application_domain` longtext DEFAULT NULL,
  `hostname` varchar(50) DEFAULT NULL,
  `vlan_id_name` varchar(50) DEFAULT NULL,
  `vlan_id` int(11) DEFAULT NULL,
  `ip_addr` varchar(20) DEFAULT NULL,
  `subnet_mask` varchar(20) DEFAULT NULL,
  `gateway` varchar(20) DEFAULT NULL,
  `vlan_int_2_name` varchar(50) DEFAULT NULL,
  `vlan_id_2` int(11) DEFAULT NULL,
  `ip_addr_2` varchar(20) DEFAULT NULL,
  `subnet_mask_2` varchar(20) DEFAULT NULL,
  `gateway_2` varchar(20) DEFAULT NULL,
  `system_category` varchar(50) DEFAULT NULL,
  `os_level` varchar(50) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=6481 DEFAULT CHARSET=ascii;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `hmc`
--

DROP TABLE IF EXISTS `hmc`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `hmc` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(50) NOT NULL,
  `version` varchar(20) NOT NULL,
  `servicepack` int(2) NOT NULL,
  `model` varchar(20) NOT NULL,
  `serialnr` varchar(20) NOT NULL,
  `ipaddr` varchar(50) NOT NULL,
  `last_update` datetime NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `id_2` (`id`),
  KEY `id` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=87 DEFAULT CHARSET=ascii;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `lpar_eth`
--

DROP TABLE IF EXISTS `lpar_eth`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `lpar_eth` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `lpar_name` varchar(50) NOT NULL,
  `slot_num` varchar(3) NOT NULL,
  `is_trunk` int(1) NOT NULL,
  `port_vlan_id` int(4) NOT NULL,
  `vswitch` varchar(50) NOT NULL,
  `mac_addr` varchar(12) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `macaddrindex` (`mac_addr`)
) ENGINE=InnoDB AUTO_INCREMENT=41277 DEFAULT CHARSET=ascii;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `lpar_fc`
--

DROP TABLE IF EXISTS `lpar_fc`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `lpar_fc` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `lpar_name` varchar(50) NOT NULL,
  `adapter_type` varchar(50) NOT NULL,
  `state` int(1) NOT NULL,
  `remote_lpar` varchar(50) NOT NULL,
  `remote_slot_num` int(11) NOT NULL,
  `wwpns` varchar(100) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `wwpnindex` (`wwpns`)
) ENGINE=InnoDB AUTO_INCREMENT=2600 DEFAULT CHARSET=ascii;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `lpar_ms`
--

DROP TABLE IF EXISTS `lpar_ms`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `lpar_ms` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `hmc_id` varchar(50) NOT NULL,
  `msname` varchar(100) NOT NULL,
  `msmodel` varchar(50) NOT NULL,
  `msserial` varchar(20) NOT NULL,
  `lparname` varchar(50) NOT NULL,
  `lparenv` varchar(50) NOT NULL,
  `lparos` varchar(100) NOT NULL,
  `lparstate` varchar(50) NOT NULL,
  `lparip` varchar(50) DEFAULT NULL,
  `rmc_state` varchar(20) NOT NULL,
  `curr_lpar_proc_compat_mode` varchar(20) NOT NULL,
  `lpar_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_lparname` (`lparname`)
) ENGINE=InnoDB AUTO_INCREMENT=8068 DEFAULT CHARSET=ascii;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `lpar_scsi`
--

DROP TABLE IF EXISTS `lpar_scsi`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `lpar_scsi` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `lpar_name` varchar(50) CHARACTER SET ascii NOT NULL,
  `slot_num` int(11) NOT NULL,
  `state` int(11) NOT NULL,
  `is_required` int(11) NOT NULL,
  `adapter_type` varchar(50) CHARACTER SET ascii NOT NULL,
  `remote_lpar_name` varchar(50) CHARACTER SET ascii NOT NULL,
  `remote_slot_num` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `myindex` (`lpar_name`,`slot_num`,`remote_lpar_name`,`remote_slot_num`)
) ENGINE=InnoDB AUTO_INCREMENT=30295 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `mem_cpu_lpars`
--

DROP TABLE IF EXISTS `mem_cpu_lpars`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `mem_cpu_lpars` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `profile_name` varchar(50) NOT NULL,
  `lpar_name` varchar(50) NOT NULL,
  `min_mem` varchar(20) NOT NULL,
  `desired_mem` varchar(20) NOT NULL,
  `max_mem` varchar(20) NOT NULL,
  `mem_mode` varchar(50) NOT NULL,
  `proc_mode` varchar(50) NOT NULL,
  `min_proc_units` varchar(10) NOT NULL,
  `desired_proc_units` varchar(10) NOT NULL,
  `max_proc_units` varchar(10) NOT NULL,
  `min_procs` varchar(10) NOT NULL,
  `desired_procs` varchar(10) NOT NULL,
  `max_procs` varchar(10) NOT NULL,
  `sharing_mode` varchar(100) NOT NULL,
  `uncap_weight` varchar(50) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_lpar_name` (`lpar_name`)
) ENGINE=InnoDB AUTO_INCREMENT=8068 DEFAULT CHARSET=ascii;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `ms_cpu`
--

DROP TABLE IF EXISTS `ms_cpu`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `ms_cpu` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `ms_name` varchar(50) NOT NULL,
  `configurable_sys_proc_units` varchar(50) NOT NULL,
  `curr_avail_sys_proc_units` varchar(50) NOT NULL,
  `deconfig_sys_proc_units` varchar(50) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_msname` (`ms_name`)
) ENGINE=InnoDB AUTO_INCREMENT=524 DEFAULT CHARSET=ascii;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `ms_fw`
--

DROP TABLE IF EXISTS `ms_fw`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `ms_fw` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `ms_name` varchar(50) NOT NULL,
  `fw_level` varchar(50) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `msindex` (`ms_name`)
) ENGINE=InnoDB AUTO_INCREMENT=524 DEFAULT CHARSET=ascii;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `ms_io`
--

DROP TABLE IF EXISTS `ms_io`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `ms_io` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `ms_name` varchar(50) NOT NULL,
  `unit_phys_loc` varchar(50) NOT NULL,
  `phys_loc` varchar(50) NOT NULL,
  `description` varchar(200) NOT NULL,
  `lpar_name` varchar(50) NOT NULL,
  `drc_name` varchar(200) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=25742 DEFAULT CHARSET=ascii;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `ms_io_subdev`
--

DROP TABLE IF EXISTS `ms_io_subdev`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `ms_io_subdev` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `ms_name` varchar(100) NOT NULL,
  `phys_loc` varchar(100) NOT NULL,
  `lpar_id` int(11) NOT NULL,
  `lpar_name` varchar(50) NOT NULL,
  `description` longtext NOT NULL,
  `device_type` longtext NOT NULL,
  `mac_address` varchar(50) NOT NULL,
  `parent` varchar(100) NOT NULL,
  `serial_num` varchar(50) NOT NULL,
  `fru_num` varchar(50) NOT NULL,
  `part_num` varchar(50) NOT NULL,
  `wwpn` varchar(50) NOT NULL,
  `wwnn` varchar(50) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=74224 DEFAULT CHARSET=ascii;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `ms_mem`
--

DROP TABLE IF EXISTS `ms_mem`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `ms_mem` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `ms_name` varchar(50) NOT NULL,
  `configurable_sys_mem` varchar(50) NOT NULL,
  `curr_avail_sys_mem` varchar(50) NOT NULL,
  `deconfig_sys_mem` varchar(50) NOT NULL,
  `sys_firmware_mem` varchar(50) NOT NULL,
  `mem_region_size` varchar(50) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_msname` (`ms_name`)
) ENGINE=InnoDB AUTO_INCREMENT=524 DEFAULT CHARSET=ascii;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `npiv`
--

DROP TABLE IF EXISTS `npiv`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `npiv` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `ms_name` varchar(100) NOT NULL,
  `vios_name` varchar(50) NOT NULL,
  `vfchost` varchar(30) NOT NULL,
  `physloc` varchar(100) NOT NULL,
  `lpar_id` int(11) NOT NULL,
  `lpar_name` varchar(50) NOT NULL,
  `lpar_os` varchar(20) NOT NULL,
  `status` varchar(20) NOT NULL,
  `fc_name` varchar(10) NOT NULL,
  `fc_loc_code` varchar(100) NOT NULL,
  `vfc_client_drc` varchar(100) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=97 DEFAULT CHARSET=ascii;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `phys_mac`
--

DROP TABLE IF EXISTS `phys_mac`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `phys_mac` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `ms_name` varchar(100) NOT NULL,
  `lpar_name` varchar(100) DEFAULT NULL,
  `phys_loc` varchar(200) NOT NULL,
  `mac_addr` varchar(20) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=92915 DEFAULT CHARSET=ascii;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `vios_fc_wwpn`
--

DROP TABLE IF EXISTS `vios_fc_wwpn`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `vios_fc_wwpn` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `ms_name` varchar(100) CHARACTER SET ascii NOT NULL,
  `vios_name` varchar(100) CHARACTER SET ascii NOT NULL,
  `fc_adapter` varchar(10) CHARACTER SET ascii NOT NULL,
  `wwpn` varchar(50) CHARACTER SET ascii NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `wwpn` (`wwpn`)
) ENGINE=InnoDB AUTO_INCREMENT=4108 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `vmware`
--

DROP TABLE IF EXISTS `vmware`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `vmware` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `vmname` varchar(100) NOT NULL,
  `uuid` longtext NOT NULL,
  `numcpu` int(11) NOT NULL,
  `memory` int(11) NOT NULL,
  `gueststate` varchar(50) NOT NULL,
  `guestfullname` varchar(200) NOT NULL,
  `guestid` varchar(200) NOT NULL,
  `configversion` varchar(50) NOT NULL,
  `firmwaretype` varchar(50) NOT NULL,
  `numcorespersocket` int(11) NOT NULL,
  `ipaddress` varchar(100) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=1800 DEFAULT CHARSET=ascii;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2018-12-21 15:47:09
