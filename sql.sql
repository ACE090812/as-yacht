-- ─────────────────────────────────────────────────────────────────────────────
-- AS YACHT DATABASE SCHEMA
-- Table schema for the yachts resource
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS `yachts` (
  `yachtid` int(11) NOT NULL AUTO_INCREMENT,
  `identifier` varchar(255) NOT NULL,
  `coords` longtext NOT NULL,
  `rotation` longtext NOT NULL,
  `flagid` int(11) NOT NULL DEFAULT 1,
  `lightid` int(11) NOT NULL DEFAULT 1,
  `lighcategoryid` int(11) NOT NULL DEFAULT 1,
  `uppertext` varchar(255) NOT NULL DEFAULT '',
  `bottomtext` varchar(255) NOT NULL DEFAULT '',
  `railingid` int(11) NOT NULL DEFAULT 1,
  `colorid` int(11) NOT NULL DEFAULT 1,
  `permissions` longtext NOT NULL,
  `furnitures` longtext NOT NULL,
  `extras` longtext NULL,
  PRIMARY KEY (`yachtid`),
  KEY `identifier` (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- Existing installs: the resource adds the `extras` column and upgrades yachtid to AUTO_INCREMENT automatically on start.
-- To do it by hand instead:
-- ALTER TABLE `yachts` MODIFY `yachtid` int(11) NOT NULL AUTO_INCREMENT;
