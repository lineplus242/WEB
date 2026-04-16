/*M!999999\- enable the sandbox mode */ 
-- MariaDB dump 10.19  Distrib 10.11.15-MariaDB, for Linux (x86_64)
--
-- Host: localhost    Database: admin_db
-- ------------------------------------------------------
-- Server version	10.11.15-MariaDB

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `tb_asset`
--

DROP TABLE IF EXISTS `tb_asset`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `tb_asset` (
  `asset_seq` int(11) NOT NULL AUTO_INCREMENT,
  `parent_seq` int(11) DEFAULT NULL,
  `cust_seq` int(11) NOT NULL,
  `asset_type` varchar(50) NOT NULL,
  `asset_role` varchar(20) DEFAULT 'PHYSICAL',
  `virt_type` varchar(20) DEFAULT NULL,
  `asset_name` varchar(200) NOT NULL,
  `model` varchar(200) DEFAULT NULL,
  `maker` varchar(100) DEFAULT NULL,
  `size_u` int(11) DEFAULT NULL,
  `hostname` varchar(100) DEFAULT NULL,
  `ip_addr` text DEFAULT NULL,
  `disk` varchar(200) DEFAULT NULL,
  `cpu` varchar(200) DEFAULT NULL,
  `memory` varchar(100) DEFAULT NULL,
  `os_info` varchar(100) DEFAULT NULL,
  `location` varchar(200) DEFAULT NULL,
  `status` varchar(20) DEFAULT 'ACTIVE',
  `purchase_dt` varchar(10) DEFAULT NULL,
  `expire_dt` varchar(10) DEFAULT NULL,
  `account_info` text DEFAULT NULL,
  `memo` text DEFAULT NULL,
  `del_yn` char(1) DEFAULT 'N',
  `reg_dt` datetime DEFAULT current_timestamp(),
  `reg_user` varchar(100) DEFAULT NULL,
  `upd_dt` datetime DEFAULT NULL ON UPDATE current_timestamp(),
  `upd_user` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`asset_seq`)
) ENGINE=InnoDB AUTO_INCREMENT=78 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tb_asset`
--

LOCK TABLES `tb_asset` WRITE;
/*!40000 ALTER TABLE `tb_asset` DISABLE KEYS */;
INSERT INTO `tb_asset` VALUES
(29,NULL,7,'SERVER','HYPERVISOR','ORACLE_VM','통합WEB#1','T7-1','Oracle',2,'KitWeb1-Ldom-Primary','[{\"type\":\"관리IP\",\"addr\":\"172.17.17.162\"},{\"type\":\"서비스IP\",\"addr\":\"172.17.17.153\"}]',NULL,'4.13Ghz 32C','128GB','Solaris 11.3','전산실','ACTIVE','2017-03-01',NULL,'[{\"username\":\"root\",\"password\":\"wkd11!#Eod\"},{\"username\":\"caslte\",\"password\":\"castle1!#\"}]',NULL,'N','2026-04-14 11:32:13','admin','2026-04-14 17:20:58','admin'),
(30,29,7,'SERVER','LDOM','VMWARE','차세대WEB#1',NULL,NULL,NULL,'ykitweb1','202.31.128.135',NULL,'24vCore','32GB','Solaris 11.4','전산실','ACTIVE',NULL,NULL,NULL,NULL,'N','2026-04-14 11:33:38','admin','2026-04-14 11:36:55','admin'),
(31,29,7,'SERVER','LDOM','VMWARE','홈페이지WEB#1',NULL,NULL,NULL,'homeweb1','202.31.128.131',NULL,'24vCore','32GB','Solaris 11.3',NULL,'ACTIVE',NULL,NULL,NULL,NULL,'N','2026-04-14 11:34:13','admin','2026-04-14 11:37:54','admin'),
(32,29,7,'SERVER','LDOM','VMWARE','개발WEB',NULL,NULL,NULL,'testWEB','202.31.128.140',NULL,'8vCore','16GB','Solaris 11.4','전산실','ACTIVE',NULL,NULL,NULL,NULL,'N','2026-04-14 11:35:01','admin','2026-04-14 11:37:21','admin'),
(33,NULL,7,'SERVER','HYPERVISOR','ORACLE_VM','통합WEB#2','T7-1','Oracle',2,'KitWeb2-Ldom-Primary','[{\"type\":\"관리IP\",\"addr\":\"172.17.17.152\"}]',NULL,'4.13Ghz 32C','128GB','Solaris 11.3','전산실','ACTIVE','2017-03-01',NULL,NULL,NULL,'N','2026-04-14 11:36:04','admin','2026-04-14 14:15:21','admin'),
(34,33,7,'SERVER','LDOM','VMWARE','차세대WEB#2',NULL,NULL,NULL,'ykitweb2','[{\"type\":\"서비스IP\",\"addr\":\"202.31.128.136\"}]',NULL,'24vCore','32GB','Solaris 11.4',NULL,'ACTIVE',NULL,NULL,NULL,NULL,'N','2026-04-14 11:36:36','admin','2026-04-14 14:15:42','admin'),
(35,33,7,'SERVER','LDOM','VMWARE','홈페이지WEB#2',NULL,NULL,NULL,'homeweb2','[{\"type\":\"서비스IP\",\"addr\":\"202.31.128.134\"}]',NULL,'24vCore','32GB',NULL,NULL,'ACTIVE',NULL,NULL,NULL,NULL,'N','2026-04-14 11:38:33','admin','2026-04-14 14:15:51','admin'),
(36,NULL,7,'SERVER','PHYSICAL','VMWARE','입시DB','M10-1','Oracle',NULL,'lim','[{\"type\":\"서비스IP\",\"addr\":\"172.17.17.131\"}]',NULL,'3.20Ghz, 4C','32GB','Solaris 10','전산실','ACTIVE','2016-05-01',NULL,NULL,NULL,'N','2026-04-14 11:40:23','admin','2026-04-14 14:15:33','admin'),
(37,NULL,7,'SERVER','HYPERVISOR','VMWARE','가상화서버#1','R750','Dell',2,'vmware1','[{\"type\":\"서비스IP\",\"addr\":\"202.31.128.162\"}]',NULL,'3.0Ghz, 18C * 2EA','512GB','VMware ESXi 7.0.3','전산실','ACTIVE','2022-10-01',NULL,NULL,NULL,'N','2026-04-14 11:42:05','admin','2026-04-14 14:15:30','admin'),
(38,NULL,7,'SERVER','HYPERVISOR','VMWARE','가상화서버#2','R740','Dell',2,'vmware2','[{\"type\":\"서비스IP\",\"addr\":\"202.31.128.163\"}]',NULL,'3.0Ghz, 12C * 2EA','512GB','VMware ESXi 7.0.3','전산실','ACTIVE','2019-10-01',NULL,NULL,NULL,'N','2026-04-14 11:43:11','admin','2026-04-14 17:24:22','admin'),
(39,NULL,7,'SERVER','HYPERVISOR','VMWARE','가상화서버#3','R740','Dell',2,'vmware3','[{\"type\":\"서비스IP\",\"addr\":\"202.31.128.164\"}]',NULL,'3.0Ghz, 12C * 2EA','512GB','VMware ESXi 7.0.3','전산실','ACTIVE','2019-10-01',NULL,NULL,NULL,'N','2026-04-14 11:43:50','admin','2026-04-14 17:24:34','admin'),
(40,NULL,7,'SERVER','HYPERVISOR','VMWARE','가상화서버#4','R940','Dell',4,'vmware4','[{\"type\":\"서비스IP\",\"addr\":\"202.31.128.21\"}]',NULL,'3.1Ghz, 18C * 4EA','1024GB','VMware ESXi 7.0.3','전산실','ACTIVE','2023-02-01',NULL,NULL,NULL,'N','2026-04-14 11:44:32','admin','2026-04-14 17:24:38','admin'),
(41,NULL,7,'SERVER','PHYSICAL','VMWARE','KESM','T5240','Oracle',NULL,'KESM','[{\"type\":\"서비스IP\",\"addr\":\"172.17.17.142\"}]',NULL,'1.16Ghz, 4C','8GB','Solaris 10','전산실','ACTIVE','2008-12-01',NULL,NULL,NULL,'N','2026-04-14 11:45:35','admin','2026-04-14 17:24:43','admin'),
(42,NULL,7,'SERVER','PHYSICAL','VMWARE','전자결재(EDMS)','T5240','Oracle',1,'edms','[{\"type\":\"서비스IP\",\"addr\":\"202.31.128.62\"}]',NULL,'1.16Ghz, 6C * 2EA','32GB','Solaris 10','전산실','ACTIVE','2009-07-01',NULL,NULL,NULL,'N','2026-04-14 11:46:44','admin','2026-04-14 17:24:55','admin'),
(43,NULL,7,'STORAGE','PHYSICAL','VMWARE','통합스토리지','VSP G400','Hitachi',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'전산실','ACTIVE','2018-11-01',NULL,NULL,NULL,'N','2026-04-14 11:47:27','admin','2026-04-14 11:48:47','admin'),
(44,NULL,7,'STORAGE','PHYSICAL','VMWARE','가상화스토리지','VSP G350','Hitachi',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'전산실','ACTIVE','2023-02-01',NULL,NULL,NULL,'N','2026-04-14 11:48:09','admin','2026-04-14 11:48:50','admin'),
(45,NULL,7,'STORAGE','PHYSICAL','VMWARE','재해복구스토리지','VSP G350','Hitachi',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'DR센터','ACTIVE','2019-10-01',NULL,NULL,NULL,'N','2026-04-14 11:48:43','admin',NULL,NULL),
(46,NULL,7,'STORAGE','PHYSICAL','VMWARE','대용량스토리지','HUS 130','Hitachi',4,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'ACTIVE','2014-06-01',NULL,NULL,NULL,'N','2026-04-14 11:49:21','admin','2026-04-15 16:44:12','admin'),
(47,NULL,7,'STORAGE','PHYSICAL','VMWARE','NAS스토리지','Unity XT380','Dell',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'ACTIVE','2022-10-01',NULL,NULL,NULL,'N','2026-04-14 11:50:00','admin',NULL,NULL),
(48,NULL,7,'NETWORK','PHYSICAL','VMWARE','DATA SAN#1','6510','Brocade',NULL,NULL,'[{\"type\":\"관리IP\",\"addr\":\"172.17.17.176\"}]',NULL,NULL,NULL,NULL,NULL,'ACTIVE','2019-07-01',NULL,NULL,NULL,'N','2026-04-14 11:50:48','admin','2026-04-14 17:24:18','admin'),
(49,NULL,7,'NETWORK','PHYSICAL','VMWARE','DATA SAN#2','6510','Brocade',NULL,NULL,'[{\"type\":\"관리IP\",\"addr\":\"172.17.17.177\"}]',NULL,NULL,NULL,NULL,NULL,'ACTIVE','2019-07-01',NULL,NULL,NULL,'N','2026-04-14 11:51:14','admin','2026-04-14 17:24:59','admin'),
(50,NULL,7,'NETWORK','PHYSICAL','VMWARE','NAS 스위치#1','OS6900-X24C2','Alcatel',1,'NAS-SW1','[{\"type\":\"관리IP\",\"addr\":\"172.30.30.2\"}]',NULL,NULL,NULL,NULL,NULL,'ACTIVE','2024-06-01',NULL,NULL,NULL,'N','2026-04-14 11:51:51','admin','2026-04-14 17:25:06','admin'),
(51,NULL,7,'NETWORK','PHYSICAL','VMWARE','NAS 스위치#2','OS6900-X24C2','Alcatel',1,'NAS-SW2','[{\"type\":\"관리IP\",\"addr\":\"172.30.30.3\"}]',NULL,NULL,NULL,NULL,NULL,'ACTIVE','2024-06-01',NULL,NULL,NULL,'N','2026-04-14 11:52:20','admin','2026-04-14 17:25:09','admin'),
(52,NULL,7,'SERVER','HYPERVISOR','ORACLE_VM','통합WAS#1','T7-4','Oracle',4,'kitDB1-Ldom-Primary','[{\"type\":\"관리IP\",\"addr\":\"172.17.17.160\"},{\"type\":\"서비스IP\",\"addr\":\"172.17.17.151\"}]',NULL,'4.13Ghz, 32C','512GB','Solaris 11.3','전산실','ACTIVE','2018-11-01',NULL,NULL,NULL,'N','2026-04-14 13:01:36',NULL,'2026-04-14 17:25:20','admin'),
(53,NULL,7,'SERVER','HYPERVISOR','ORACLE_VM','통합WAS#2','T8-4','Oracle',4,'kitDB2-Ldom_primary','[{\"type\":\"관리IP\",\"addr\":\"172.17.17.159\"},{\"type\":\"서비스IP\",\"addr\":\"172.17.17.155\"}]',NULL,'5.06Ghz 32C','512GB','Solaris 11.3','전산실','ACTIVE','2019-10-01',NULL,NULL,NULL,'N','2026-04-14 13:03:05','admin','2026-04-14 17:25:29','admin'),
(54,NULL,8,'SERVER','PHYSICAL','VMWARE','스마트주차플랫폼 WEB#1','SF7-2212W E1','이슬림코리아',2,NULL,'[{\"type\":\"관리IP\",\"addr\":\"192.168.0.14\"},{\"type\":\"서비스IP\",\"addr\":\"172.16.1.11\"}]',NULL,NULL,NULL,'Rocky Linux 9.6',NULL,'ACTIVE',NULL,NULL,'[{\"username\":\"castle\",\"password\":\"castle1!\"},{\"username\":\"root\",\"password\":\"root123\"}]',NULL,'N','2026-04-16 10:09:23','admin',NULL,NULL),
(55,NULL,8,'SERVER','PHYSICAL','VMWARE','스마트주차플랫폼 WEB#2','SF7-2212W E1','이슬림코리아',2,NULL,'[{\"type\":\"관리IP\",\"addr\":\"192.168.0.15\"},{\"type\":\"서비스IP\",\"addr\":\"172.16.1.12\"}]',NULL,NULL,NULL,'Rocky Linux 9.6',NULL,'ACTIVE',NULL,NULL,'[{\"username\":\"castle\",\"password\":\"castle1!\"},{\"username\":\"root\",\"password\":\"root123\"}]',NULL,'N','2026-04-16 10:09:32','admin','2026-04-16 10:10:34','admin'),
(56,NULL,8,'SERVER','PHYSICAL','VMWARE','스마트주차플랫폼 WAS#1','SF7-2212W E1','이슬림코리아',2,NULL,'[{\"type\":\"관리IP\",\"addr\":\"192.168.0.30\"},{\"type\":\"서비스IP\",\"addr\":\"100.2.199.102\"}]',NULL,NULL,NULL,'Rocky Linux 9.6',NULL,'ACTIVE',NULL,NULL,'[{\"username\":\"castle\",\"password\":\"castle1!\"},{\"username\":\"root\",\"password\":\"root123\"}]',NULL,'N','2026-04-16 10:11:33','admin','2026-04-16 10:13:49','admin'),
(57,NULL,8,'SERVER','PHYSICAL','VMWARE','스마트주차플랫폼 WAS#2','SF7-2212W E1','이슬림코리아',2,NULL,'[{\"type\":\"관리IP\",\"addr\":\"192.168.0.31\"},{\"type\":\"서비스IP\",\"addr\":\"100.2.199.103\"}]',NULL,NULL,NULL,'Rocky Linux 9.6',NULL,'ACTIVE',NULL,NULL,'[{\"username\":\"castle\",\"password\":\"castle1!\"},{\"username\":\"root\",\"password\":\"root123\"}]',NULL,'N','2026-04-16 10:12:24','admin',NULL,NULL),
(58,NULL,8,'SERVER','PHYSICAL','VMWARE','스마트주차플랫폼 DB#1','SF7-2212W E1','이슬림코리아',2,NULL,'[{\"type\":\"관리IP\",\"addr\":\"192.168.0.32\"},{\"type\":\"서비스IP\",\"addr\":\"100.2.199.105\"}]',NULL,NULL,NULL,'Rocky Linux 9.6',NULL,'ACTIVE',NULL,NULL,'[{\"username\":\"castle\",\"password\":\"castle1!\"},{\"username\":\"root\",\"password\":\"root123\"}]',NULL,'N','2026-04-16 10:12:54','admin','2026-04-16 10:13:40','admin'),
(59,NULL,8,'SERVER','PHYSICAL','VMWARE','스마트주차플랫폼 DB#2','SF7-2212W E1','이슬림코리아',2,NULL,'[{\"type\":\"관리IP\",\"addr\":\"192.168.0.33\"},{\"type\":\"서비스IP\",\"addr\":\"100.2.199.106\"}]',NULL,NULL,NULL,'Rocky Linux 9.6',NULL,'ACTIVE',NULL,NULL,'[{\"username\":\"castle\",\"password\":\"castle1!\"},{\"username\":\"root\",\"password\":\"root123\"}]',NULL,'N','2026-04-16 10:20:06','admin',NULL,NULL),
(60,NULL,8,'SERVER','PHYSICAL','VMWARE','스마트주차플랫폼 중계서버','SF7-2212W E1','이슬림코리아',2,NULL,'[{\"type\":\"관리IP\",\"addr\":\"192.168.0.16\"},{\"type\":\"서비스IP\",\"addr\":\"172.16.1.20\"}]',NULL,NULL,NULL,'Ubuntu 22.05',NULL,'ACTIVE',NULL,NULL,'[{\"username\":\"castle\",\"password\":\"castle1!\"},{\"username\":\"bumil\",\"password\":\"bumil\"}]',NULL,'N','2026-04-16 10:21:06','admin',NULL,NULL),
(61,NULL,8,'STORAGE','PHYSICAL','VMWARE','스마트주차플랫폼 스토리지','Power Vault ME5024','DELL',2,NULL,'[{\"type\":\"관리IP\",\"addr\":\"192.168.0.18\"},{\"type\":\"관리IP\",\"addr\":\"192.168.0.19\"}]',NULL,NULL,NULL,NULL,NULL,'ACTIVE',NULL,NULL,'[{\"username\":\"bumil\",\"password\":\"wkd11!#Eod\"}]','Controller A : 192.168.0.18 Controller B : 192.168.0.19 \r\nWEB : Controller A : https://192.168.0.18/ Controller B : https://192.168.0.19/','N','2026-04-16 10:22:52','admin','2026-04-16 10:48:27','admin'),
(62,NULL,8,'NETWORK','PHYSICAL','VMWARE','스마트주차플랫폼 SAN스위치','CTX MDS-9132T','DELL',1,NULL,'[{\"type\":\"관리IP\",\"addr\":\"192.168.0.20\"}]',NULL,NULL,NULL,NULL,NULL,'ACTIVE',NULL,NULL,'[{\"username\":\"admin\",\"password\":\"Passw0rd\"}]',NULL,'N','2026-04-16 10:23:47','admin',NULL,NULL),
(63,NULL,8,'NETWORK','PHYSICAL','VMWARE','스마트주차플랫폼 내부망 L4 스위치','PAS-K3200','PIOLINK',2,NULL,'[{\"type\":\"관리IP\",\"addr\":\"192.168.0.25\"},{\"type\":\"서비스IP\",\"addr\":\"100.2.199.30\"}]',NULL,NULL,NULL,NULL,NULL,'ACTIVE',NULL,NULL,'[{\"username\":\"admin\",\"password\":\"Qwe123!@#\"}]',NULL,'N','2026-04-16 10:25:02','admin',NULL,NULL),
(64,NULL,8,'NETWORK','PHYSICAL','VMWARE','스마트주차플랫폼 인터넷망 L4 스위치','PAS-K3200','PIOLINK',2,NULL,'[{\"type\":\"관리IP\",\"addr\":\"192.168.0.11\"},{\"type\":\"서비스IP\",\"addr\":\"172.16.1.30\"}]',NULL,NULL,NULL,NULL,NULL,'ACTIVE',NULL,NULL,'[{\"username\":\"admin\",\"password\":\"Qwe123!@#\"}]',NULL,'N','2026-04-16 10:26:05','admin',NULL,NULL),
(65,NULL,8,'NETWORK','PHYSICAL','VMWARE','스마트주차플랫폼 내부망 L3 스위치','EX3400-24T','JUNIPER',1,NULL,'[{\"type\":\"관리IP\",\"addr\":\"192.168.0.26\"},{\"type\":\"서비스IP\",\"addr\":\"100.2.199.254\"}]',NULL,NULL,NULL,NULL,NULL,'ACTIVE',NULL,NULL,'[{\"username\":\"ddc\",\"password\":\"ddcseoul10@\"}]',NULL,'N','2026-04-16 10:28:44','admin','2026-04-16 10:31:22','admin'),
(66,NULL,8,'NETWORK','PHYSICAL','VMWARE','스마트주차플랫폼 인터넷망 L3 스위치','EX3400-24T','JUNIPER',1,NULL,'[{\"type\":\"관리IP\",\"addr\":\"192.168.0.10\"},{\"type\":\"서비스IP\",\"addr\":\"172.16.1.254\"}]',NULL,NULL,NULL,NULL,NULL,'ACTIVE',NULL,NULL,'[{\"username\":\"ddc\",\"password\":\"ddcseoul10@\"}]',NULL,'N','2026-04-16 10:31:10','admin',NULL,NULL),
(67,NULL,8,'NETWORK','PHYSICAL','VMWARE','스마트주차플랫폼 인터넷망 라우터','SRX345-SYS-JB-2AC','JUNIPER',1,NULL,'[{\"type\":\"관리IP\",\"addr\":\"192.168.0.1\"},{\"type\":\"서비스IP\",\"addr\":\"152.99.25.241\"},{\"type\":\"서비스IP\",\"addr\":\"152.99.25.249 (IPSenVPN통신용)\"}]',NULL,NULL,NULL,NULL,NULL,'ACTIVE',NULL,NULL,'[{\"username\":\"ddc\",\"password\":\"ddcseoul10@\"}]',NULL,'N','2026-04-16 10:32:37','admin','2026-04-16 10:37:50','admin'),
(68,NULL,8,'SECURITY','PHYSICAL','VMWARE','스마트주차플랫폼 인터넷망 방화벽','SNIPER NGFW 3130','WINS',2,NULL,'[{\"type\":\"관리IP\",\"addr\":\"192.168.0.3\"},{\"type\":\"서비스IP\",\"addr\":\"152.99.25.250\"},{\"type\":\"서비스IP\",\"addr\":\"152.99.25.251 (중계NAT)\"},{\"type\":\"서비스IP\",\"addr\":\"152.99.25.252 (WEB VIP)\"}]',NULL,NULL,NULL,NULL,NULL,'ACTIVE',NULL,NULL,'[{\"username\":\"Manager\",\"password\":\"sniper_001\"}]','WEB\r\nhttps://192.168.0.3:8443/','N','2026-04-16 10:35:02','admin','2026-04-16 10:39:21','admin'),
(69,NULL,8,'SECURITY','PHYSICAL','VMWARE','스마트주차플랫폼 내부망 방화벽','SNIPER NGFW 3130','WINS',2,NULL,'[{\"type\":\"관리IP\",\"addr\":\"192.168.0.27\"}]',NULL,NULL,NULL,NULL,NULL,'ACTIVE',NULL,NULL,'[{\"username\":\"Manager\",\"password\":\"sniper_001\"}]','WEB\r\nhttps://192.168.0.27:8443/','N','2026-04-16 10:35:53','admin','2026-04-16 10:39:50','admin'),
(70,NULL,8,'SECURITY','PHYSICAL','VMWARE','스마트주차플랫폼 망연계 방화벽','SNIPER NGFW 3130','WINS',2,NULL,'[{\"type\":\"관리IP\",\"addr\":\"192.168.0.12\"}]',NULL,NULL,NULL,NULL,NULL,'ACTIVE',NULL,NULL,'[{\"username\":\"Manager\",\"password\":\"sniper_001\"}]','WEB\r\nhttps://192.168.0.12:8443/','N','2026-04-16 10:36:30','admin','2026-04-16 10:39:57','admin'),
(71,NULL,8,'SECURITY','PHYSICAL','VMWARE','스마트주차플랫폼 IPSecVPN','SNIPER NGFW 3130','WINS',2,NULL,'[{\"type\":\"관리IP\",\"addr\":\"192.168.0.4\"},{\"type\":\"서비스IP\",\"addr\":\"152.99.25.242\"}]',NULL,NULL,NULL,NULL,NULL,'ACTIVE',NULL,NULL,'[{\"username\":\"Manager\",\"password\":\"sniper_001\"}]','WEB\r\nhttps://192.168.0.4:8443/','N','2026-04-16 10:37:35','admin','2026-04-16 10:40:04','admin'),
(72,NULL,8,'SECURITY','PHYSICAL','VMWARE','스마트주차플랫폼 WAF','AIWAF-500_Y20','모니터랩',2,NULL,'[{\"type\":\"관리IP\",\"addr\":\"192.168.0.6\"}]',NULL,NULL,NULL,NULL,NULL,'ACTIVE',NULL,NULL,'[{\"username\":\"aiadmin\",\"password\":\"numner1aiwaf\"}]',NULL,'N','2026-04-16 10:41:18','admin',NULL,NULL),
(73,NULL,8,'SECURITY','PHYSICAL','VMWARE','스마트주차플랫폼 IPS','SNIPER ONE-I 2300','WINS',2,NULL,'[{\"type\":\"관리IP\",\"addr\":\"192.168.0.7\"}]',NULL,NULL,NULL,NULL,NULL,'ACTIVE',NULL,NULL,'[{\"username\":\"root\",\"password\":\"sniper!#@$\"}]','ETH0 : 192.168.0.7','N','2026-04-16 10:42:48','admin',NULL,NULL),
(74,NULL,8,'SECURITY','PHYSICAL','VMWARE','스마트주차플랫폼 DMZ망연계 IS',NULL,'휴네시온',NULL,NULL,'[{\"type\":\"서비스IP\",\"addr\":\"100.2.199.100\"}]',NULL,NULL,NULL,NULL,NULL,'ACTIVE',NULL,NULL,'[{\"username\":\"onenet\",\"password\":\"Bellock1!\"},{\"username\":\"manager\",\"password\":\"wjstks2460!\"}]','WEB : https://100.2.199.100:3300/stream/','N','2026-04-16 10:45:12','admin','2026-04-16 10:47:43','admin'),
(75,NULL,8,'SECURITY','PHYSICAL','VMWARE','스마트주차플랫폼 DMZ망연계 ES',NULL,'휴네시온',2,NULL,'[{\"type\":\"서비스IP\",\"addr\":\"172.16.1.100\"}]',NULL,NULL,NULL,NULL,NULL,'ACTIVE',NULL,NULL,'[{\"username\":\"onenet\",\"password\":\"Bellock1!\"}]',NULL,'N','2026-04-16 10:46:12','admin',NULL,NULL),
(76,NULL,8,'SECURITY','PHYSICAL','VMWARE','스마트주차플랫폼 공영주차장 망연계 IS',NULL,'휴네시온',2,NULL,'[{\"type\":\"서비스IP\",\"addr\":\"100.2.199.100\"}]',NULL,NULL,NULL,NULL,NULL,'ACTIVE',NULL,NULL,'[{\"username\":\"onenet\",\"password\":\"Bellock1!\"},{\"username\":\"manager\",\"password\":\"wjstks2460!\"}]','WEB : https://172.16.2.254:3300/stream/','N','2026-04-16 10:47:23','admin','2026-04-16 10:47:55','admin'),
(77,NULL,8,'SECURITY','PHYSICAL','VMWARE','스마트주차플랫폼 공영주차장 망연계 IS',NULL,'휴네시온',2,NULL,'[{\"type\":\"서비스IP\",\"addr\":\"172.17.1.1\"}]',NULL,NULL,NULL,NULL,NULL,'ACTIVE',NULL,NULL,'[{\"username\":\"onenet\",\"password\":\"bellock1!\"}]',NULL,'N','2026-04-16 10:49:31','admin',NULL,NULL);
/*!40000 ALTER TABLE `tb_asset` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tb_asset_photo`
--

DROP TABLE IF EXISTS `tb_asset_photo`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `tb_asset_photo` (
  `photo_seq` int(11) NOT NULL AUTO_INCREMENT,
  `asset_seq` int(11) NOT NULL,
  `side` char(1) NOT NULL DEFAULT 'F',
  `file_path` varchar(500) NOT NULL,
  `orig_name` varchar(200) DEFAULT NULL,
  `reg_dt` datetime DEFAULT current_timestamp(),
  PRIMARY KEY (`photo_seq`),
  UNIQUE KEY `uq_asset_side` (`asset_seq`,`side`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tb_asset_photo`
--

LOCK TABLES `tb_asset_photo` WRITE;
/*!40000 ALTER TABLE `tb_asset_photo` DISABLE KEYS */;
/*!40000 ALTER TABLE `tb_asset_photo` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tb_customer`
--

DROP TABLE IF EXISTS `tb_customer`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `tb_customer` (
  `cust_seq` int(11) NOT NULL AUTO_INCREMENT COMMENT '고객사 순번',
  `cust_code` varchar(20) NOT NULL COMMENT '고객사 코드 (CUST-0001)',
  `cust_name` varchar(100) NOT NULL COMMENT '고객사명',
  `biz_no` varchar(20) DEFAULT NULL COMMENT '사업자번호 (000-00-00000)',
  `ceo_name` varchar(50) DEFAULT NULL COMMENT '대표자명',
  `industry` varchar(50) DEFAULT NULL COMMENT '업종',
  `address` varchar(200) DEFAULT NULL COMMENT '주소',
  `phone` varchar(20) DEFAULT NULL COMMENT '대표 전화',
  `email` varchar(100) DEFAULT NULL COMMENT '대표 이메일',
  `manager_name` varchar(50) DEFAULT NULL COMMENT '담당자명',
  `manager_tel` varchar(20) DEFAULT NULL COMMENT '담당자 연락처',
  `manager_email` varchar(100) DEFAULT NULL COMMENT '담당자 이메일',
  `contract_start` date DEFAULT NULL COMMENT '계약 시작일',
  `contract_end` date DEFAULT NULL COMMENT '계약 종료일',
  `service_type` varchar(50) DEFAULT NULL COMMENT '서비스 유형',
  `contract_amt` bigint(20) DEFAULT 0 COMMENT '계약금액 (원)',
  `status` varchar(20) NOT NULL DEFAULT 'ACTIVE' COMMENT '상태 (ACTIVE/INACTIVE/PENDING)',
  `memo` text DEFAULT NULL COMMENT '메모',
  `del_yn` char(1) NOT NULL DEFAULT 'N' COMMENT '삭제여부',
  `reg_user` varchar(50) DEFAULT NULL COMMENT '등록자',
  `reg_dt` datetime NOT NULL DEFAULT current_timestamp() COMMENT '등록일시',
  `upd_user` varchar(50) DEFAULT NULL COMMENT '수정자',
  `upd_dt` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp() COMMENT '수정일시',
  PRIMARY KEY (`cust_seq`),
  UNIQUE KEY `uk_cust_code` (`cust_code`),
  KEY `idx_cust_name` (`cust_name`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='고객사';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tb_customer`
--

LOCK TABLES `tb_customer` WRITE;
/*!40000 ALTER TABLE `tb_customer` DISABLE KEYS */;
INSERT INTO `tb_customer` VALUES
(7,'CUST-0001','국립금오공과대학교','','',NULL,'','','',NULL,NULL,NULL,NULL,NULL,NULL,0,'ACTIVE','','N','admin','2026-04-13 17:15:51',NULL,'2026-04-13 17:15:51'),
(8,'CUST-0008','동구청','','',NULL,'','','',NULL,NULL,NULL,NULL,NULL,NULL,0,'ACTIVE','','N','admin','2026-04-16 10:06:14',NULL,'2026-04-16 10:06:14');
/*!40000 ALTER TABLE `tb_customer` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tb_customer_manager`
--

DROP TABLE IF EXISTS `tb_customer_manager`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `tb_customer_manager` (
  `manager_seq` int(11) NOT NULL AUTO_INCREMENT,
  `cust_seq` int(11) NOT NULL,
  `manager_name` varchar(100) DEFAULT NULL,
  `manager_tel` varchar(50) DEFAULT NULL,
  `manager_email` varchar(200) DEFAULT NULL,
  `sort_order` int(11) DEFAULT 0,
  PRIMARY KEY (`manager_seq`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tb_customer_manager`
--

LOCK TABLES `tb_customer_manager` WRITE;
/*!40000 ALTER TABLE `tb_customer_manager` DISABLE KEYS */;
INSERT INTO `tb_customer_manager` VALUES
(1,7,'하창호','','',0);
/*!40000 ALTER TABLE `tb_customer_manager` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tb_login_log`
--

DROP TABLE IF EXISTS `tb_login_log`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `tb_login_log` (
  `log_seq` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '로그 순번',
  `user_id` varchar(50) DEFAULT NULL COMMENT '로그인 시도 아이디',
  `ip_addr` varchar(45) DEFAULT NULL COMMENT '클라이언트 IP',
  `result` char(1) NOT NULL COMMENT '결과 (S:성공 / F:실패)',
  `fail_reason` varchar(200) DEFAULT NULL COMMENT '실패 사유',
  `login_dt` datetime NOT NULL DEFAULT current_timestamp() COMMENT '로그인 시도 일시',
  PRIMARY KEY (`log_seq`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_login_dt` (`login_dt`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='로그인 이력';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tb_login_log`
--

LOCK TABLES `tb_login_log` WRITE;
/*!40000 ALTER TABLE `tb_login_log` DISABLE KEYS */;
/*!40000 ALTER TABLE `tb_login_log` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tb_port_map`
--

DROP TABLE IF EXISTS `tb_port_map`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `tb_port_map` (
  `port_seq` int(11) NOT NULL AUTO_INCREMENT,
  `asset_seq` int(11) NOT NULL,
  `src_port` varchar(100) NOT NULL,
  `dst_asset_seq` int(11) DEFAULT NULL,
  `dst_device_name` varchar(200) DEFAULT NULL,
  `dst_port` varchar(100) DEFAULT NULL,
  `cable_type` varchar(50) DEFAULT NULL,
  `cable_color` varchar(20) DEFAULT NULL,
  `memo` text DEFAULT NULL,
  `sort_order` int(11) DEFAULT 0,
  `reg_dt` datetime DEFAULT current_timestamp(),
  `upd_dt` datetime DEFAULT NULL ON UPDATE current_timestamp(),
  PRIMARY KEY (`port_seq`)
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tb_port_map`
--

LOCK TABLES `tb_port_map` WRITE;
/*!40000 ALTER TABLE `tb_port_map` DISABLE KEYS */;
INSERT INTO `tb_port_map` VALUES
(7,29,'S1_P2',48,'DATA SAN#1','P2',NULL,NULL,NULL,1,'2026-04-16 09:44:04',NULL);
/*!40000 ALTER TABLE `tb_port_map` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tb_project`
--

DROP TABLE IF EXISTS `tb_project`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `tb_project` (
  `proj_seq` int(11) NOT NULL AUTO_INCREMENT,
  `cust_seq` int(11) NOT NULL,
  `proj_name` varchar(200) NOT NULL,
  `contract_amt` bigint(20) DEFAULT 0,
  `contract_start` varchar(10) DEFAULT NULL,
  `contract_end` varchar(10) DEFAULT NULL,
  `status` varchar(20) DEFAULT 'ACTIVE',
  `manager_name` varchar(100) DEFAULT NULL,
  `memo` text DEFAULT NULL,
  `del_yn` char(1) DEFAULT 'N',
  `reg_dt` datetime DEFAULT current_timestamp(),
  `reg_user` varchar(100) DEFAULT NULL,
  `upd_dt` datetime DEFAULT NULL ON UPDATE current_timestamp(),
  `upd_user` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`proj_seq`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tb_project`
--

LOCK TABLES `tb_project` WRITE;
/*!40000 ALTER TABLE `tb_project` DISABLE KEYS */;
INSERT INTO `tb_project` VALUES
(1,4,'ㅁㄴㅇㅁㄴㅇ',23333,'2002-12-01','2003-03-01','ACTIVE','이지환','','Y','2026-04-08 14:56:19','admin','2026-04-08 14:59:13','admin'),
(2,4,'asdsad',0,NULL,NULL,'ACTIVE','','','Y','2026-04-08 15:17:36','admin','2026-04-08 15:17:44','admin'),
(3,4,'테스트사업',500000,'2026-04-02','2026-04-09','ACTIVE','이지환, 이현재','','N','2026-04-08 20:57:09','admin','2026-04-08 21:35:47','admin');
/*!40000 ALTER TABLE `tb_project` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tb_rack`
--

DROP TABLE IF EXISTS `tb_rack`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `tb_rack` (
  `rack_seq` int(11) NOT NULL AUTO_INCREMENT,
  `cust_seq` int(11) NOT NULL,
  `rack_name` varchar(100) NOT NULL,
  `total_u` int(11) DEFAULT 42,
  `location` varchar(200) DEFAULT NULL,
  `memo` text DEFAULT NULL,
  `sort_order` int(11) DEFAULT 0,
  `del_yn` char(1) DEFAULT 'N',
  `reg_dt` datetime DEFAULT current_timestamp(),
  PRIMARY KEY (`rack_seq`)
) ENGINE=InnoDB AUTO_INCREMENT=20 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tb_rack`
--

LOCK TABLES `tb_rack` WRITE;
/*!40000 ALTER TABLE `tb_rack` DISABLE KEYS */;
INSERT INTO `tb_rack` VALUES
(18,7,'1',42,NULL,NULL,0,'N','2026-04-14 13:03:29'),
(19,7,'2',42,NULL,NULL,1,'N','2026-04-14 13:57:03');
/*!40000 ALTER TABLE `tb_rack` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tb_rack_unit`
--

DROP TABLE IF EXISTS `tb_rack_unit`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `tb_rack_unit` (
  `unit_seq` int(11) NOT NULL AUTO_INCREMENT,
  `rack_seq` int(11) NOT NULL,
  `side` char(1) DEFAULT 'F',
  `start_u` int(11) NOT NULL,
  `size_u` int(11) DEFAULT 1,
  `device_name` varchar(200) NOT NULL,
  `device_type` varchar(50) DEFAULT 'SERVER',
  `ip_addr` text DEFAULT NULL,
  `memo` text DEFAULT NULL,
  `reg_dt` datetime DEFAULT current_timestamp(),
  PRIMARY KEY (`unit_seq`)
) ENGINE=InnoDB AUTO_INCREMENT=16 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tb_rack_unit`
--

LOCK TABLES `tb_rack_unit` WRITE;
/*!40000 ALTER TABLE `tb_rack_unit` DISABLE KEYS */;
INSERT INTO `tb_rack_unit` VALUES
(9,18,'F',8,2,'통합WEB#1','SERVER','MGMT: 172.17.17.162,SVC: 172.17.17.153',NULL,'2026-04-14 13:21:39'),
(11,18,'F',4,1,'NAS 스위치#1','NETWORK',NULL,NULL,'2026-04-14 13:54:28'),
(13,18,'F',14,1,'입시DB','SERVER',NULL,NULL,'2026-04-14 13:55:36'),
(14,18,'F',11,1,'입시DB','SERVER',NULL,NULL,'2026-04-14 14:31:25'),
(15,18,'F',27,4,'대용량스토리지','STORAGE',NULL,NULL,'2026-04-15 16:44:22');
/*!40000 ALTER TABLE `tb_rack_unit` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tb_user`
--

DROP TABLE IF EXISTS `tb_user`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `tb_user` (
  `user_seq` int(11) NOT NULL AUTO_INCREMENT COMMENT '사용자 순번',
  `user_id` varchar(50) NOT NULL COMMENT '로그인 아이디',
  `password` varchar(128) NOT NULL COMMENT 'SHA-256 해시 (HEX)',
  `user_name` varchar(50) NOT NULL COMMENT '이름',
  `email` varchar(100) DEFAULT NULL COMMENT '이메일',
  `role` varchar(20) NOT NULL DEFAULT 'USER' COMMENT '권한 (ADMIN / USER)',
  `use_yn` char(1) NOT NULL DEFAULT 'Y' COMMENT '사용여부',
  `del_yn` char(1) NOT NULL DEFAULT 'N' COMMENT '삭제여부',
  `last_login` datetime DEFAULT NULL COMMENT '마지막 로그인 일시',
  `reg_dt` datetime NOT NULL DEFAULT current_timestamp() COMMENT '등록일시',
  `upd_dt` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp() COMMENT '수정일시',
  PRIMARY KEY (`user_seq`),
  UNIQUE KEY `uk_user_id` (`user_id`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='사용자';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tb_user`
--

LOCK TABLES `tb_user` WRITE;
/*!40000 ALTER TABLE `tb_user` DISABLE KEYS */;
INSERT INTO `tb_user` VALUES
(1,'admin','32343062653531386661626432373234646462366630346565623164613539363734343864376538333163303863386661383232383039663734633732306139','관리자','admin@company.com','ADMIN','Y','N','2026-04-16 10:01:13','2026-04-07 15:21:07','2026-04-16 10:01:13'),
(2,'user01','38333163323337393238653632313262656461613434353161353134616365333137343536326636373631663661313537613266653530383262333665326662','홍길동','hong@company.com','USER','Y','Y',NULL,'2026-04-07 15:21:07','2026-04-08 20:37:04'),
(3,'lee','63303466666431663964386135393132333864303862633830653536646232333861313635363133393838656238326635306637643736363638353163343761','이지환',NULL,'USER','Y','N','2026-04-13 11:35:36','2026-04-08 20:44:58','2026-04-13 11:35:36'),
(4,'test','63303466666431663964386135393132333864303862633830653536646232333861313635363133393838656238326635306637643736363638353163343761','테스트01',NULL,'USER','Y','N',NULL,'2026-04-08 20:45:25','2026-04-08 20:46:21');
/*!40000 ALTER TABLE `tb_user` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-04-16 11:08:28
