require 'sqlite3'
require_relative 'events'

module Ektoplayer 
   class Database
      SELECT_DESCRIPTION = %q[
         SELECT description
         FROM   albums
         WHERE  url = ?
      ].squeeze(' ').freeze

      SELECT_ARCHIVES = %q[
         SELECT archive_url, archive_type
         FROM   archive_urls
         JOIN   tracks AS t ON t.album_url = archive_urls.album_url
         WHERE  t.url = ?
      ].squeeze(' ').freeze

      SELECT = %q[
      SELECT
         %{SELECT_COLUMNS}
      FROM (
         SELECT DISTINCT
            t.url             AS url,
            t.album_url       AS album_url,
            t.title           AS title,
            t.artist          AS artist,
            t.remix           AS remix,
            t.number          AS number,
            t.bpm             AS bpm,

            a.artist          AS album_artist,
            a.title           AS album,
            a.cover_url       AS cover_url,
            a.description     AS description,
            a.date            AS date,
            a.rating          AS rating,
            a.votes           AS votes,
            a.download_count  AS download_count,

            strftime('%%Y', date)  AS year,
            strftime('%%m', date)  AS month,
            strftime('%%d', date)  AS day,

            a_s.style         AS style,

            (
               SELECT GROUP_CONCAT(style)
               FROM  albums_styles
               WHERE albums_styles.album_url = t.album_url
            ) AS styles
         FROM
            tracks AS t

         JOIN albums        AS a   ON a.url = t.album_url
         JOIN albums_styles AS a_s ON a.url = a_s.album_url
      )

      WHERE 1  %{WHERE}
      GROUP BY %{GROUP_BY}
      ORDER BY %{ORDER_BY}
      %{LIMIT} ].squeeze(' ').freeze

      attr_reader :db, :events

      def initialize(db_file)
         @db = SQLite3::Database.new db_file
         @db.results_as_hash = true
         @events = Events.new(:changed)
         create_tables
      end

      private def create_tables
         @db.execute_batch %q{
         CREATE TABLE IF NOT EXISTS albums (
            url              TEXT   NOT NULL,
            title            TEXT   NOT NULL,
            artist           TEXT,  
            cover_url        TEXT,  
            description      TEXT,  
            date             DATE,  
            rating           FLOAT  NOT NULL DEFAULT -1,  
            votes            INT    NOT NULL DEFAULT 0,
            download_count   INT    NOT NULL DEFAULT 0,
            PRIMARY KEY (url)
         );
         CREATE TABLE IF NOT EXISTS tracks (
            url              TEXT   NOT NULL,
            album_url        TEXT   NOT NULL REFERENCES albums(url),
            title            TEXT   NOT NULL,
            artist           TEXT   NOT NULL,
            remix            TEXT,
            number           INT    NOT NULL,
            bpm              INT,
            PRIMARY KEY (url)
         );
         CREATE TABLE IF NOT EXISTS styles (
            style            TEXT   NOT NULL,
            url              TEXT   NOT NULL,
            PRIMARY KEY (style)
         );
         CREATE TABLE IF NOT EXISTS archive_urls (
            album_url        TEXT   NOT NULL REFERENCES albums(url),
            archive_url      TEXT   NOT NULL,
            archive_type     TEXT   NOT NULL,
            PRIMARY KEY (album_url, archive_url)
         );
         CREATE TABLE IF NOT EXISTS albums_styles (
            album_url        TEXT   NOT NULL REFERENCES albums(url),
            style            TEXT   NOT NULL REFERENCES styles(style),
            PRIMARY KEY (album_url, style)
         );} 
      end

      private def drop_tables
         %w(albums_styles archive_urls styles tracks albums).
            each { |t| @db.execute("DROP TABLE IF EXISTS #{t}") }
      end

      def transaction
         @db.transaction rescue Application.log(self, $!)
      end

      def commit
         @db.commit rescue Application.log(self, $!)
      end

      def insert_into(table, hash, mode: :insert)
         cols   = ?( + (hash.keys * ?,) + ?)
         values = ?( + (([??] * hash.size) * ?,) + ?)
         q = @db.prepare "#{mode} INTO #{table} #{cols} VALUES #{values}"
         q.bind_params(hash.values)
         q.execute
         @events.trigger(:changed)
      rescue
         Application.log(self, hash, $!)
      end

      def replace_into(table, hash)
         insert_into(table, hash, mode: :replace)
      end

      def execute(query, params=[])
         @db.execute(query, *params)
      rescue
         Application.log(self, $!)
      end

      def select(
         columns: 'number,artist,album,title,styles,date,year,rating,votes,download_count,bpm,album_url,url',
         filters: [],
         group_by: 'url',
         order_by: 'album,number',
         limit: nil
      )
         where_clauses, where_params = [], []
              
         filters.each do |filter|
            where_clauses << "AND #{filter[:tag]} #{filter[:operator]} ?"
            where_params  << filter[:value]
         end

         if order_by.is_a?Array
            fail ArgumentError, 'order_by is empty' if order_by.empty?
            order_by = order_by.join(?,)
         else
            fail ArgumentError, 'order_by is empty' if order_by.empty?
         end

         if group_by.is_a?Array
            fail ArgumentError, 'group_by is empty' if group_by.empty?
            group_by = group_by.join(?,)
         else
            fail ArgumentError, 'group_by is empty' if group_by.empty?
         end

         limit = "LIMIT #{limit}" if limit

         query = SELECT % {
            SELECT_COLUMNS: columns,
            WHERE:          where_clauses.join(' '),
            GROUP_BY:       group_by,
            ORDER_BY:       order_by,
            LIMIT:          limit
         }

         @db.execute(query, *where_params)
      rescue
         Application.log(self, $!)
      end

      def get_archives(url)
         execute(SELECT_ARCHIVES, [url])
      end

      def get_description(album_url)
         @db.get_first_value(SELECT_DESCRIPTION, [album_url])
      end

      def track_count
         @db.get_first_value('SELECT COUNT(*) FROM tracks')
      end

      def album_count
         @db.get_first_value('SELECT COUNT(*) FROM albums')
      end
   end
end
