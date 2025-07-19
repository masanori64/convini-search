--
-- PostgreSQL database dump
--

-- Dumped from database version 17.5 (Ubuntu 17.5-1.pgdg24.04+1)
-- Dumped by pg_dump version 17.5 (Ubuntu 17.5-1.pgdg24.04+1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: pgroonga; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgroonga WITH SCHEMA public;


--
-- Name: EXTENSION pgroonga; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pgroonga IS 'Super fast and all languages supported full text search index based on Groonga';


--
-- Name: postgis; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA public;


--
-- Name: EXTENSION postgis; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION postgis IS 'PostGIS geometry and geography spatial types and functions';


--
-- Name: expand_synonym(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.expand_synonym(text) RETURNS text
    LANGUAGE sql STABLE PARALLEL SAFE
    AS $_$SELECT pgroonga_query_expand('public.synonyms','term','synonyms',$1);$_$;


ALTER FUNCTION public.expand_synonym(text) OWNER TO postgres;

--
-- Name: refresh_synonyms(); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.refresh_synonyms()
    LANGUAGE plpgsql
    AS $$
BEGIN
  TRUNCATE public.synonyms;
  WITH exploded AS (
        SELECT unnest(sg.synonyms) AS term, sg.synonyms
          FROM public.synonym_groups sg )
  INSERT INTO public.synonyms(term,synonyms)
  SELECT term, array_agg(DISTINCT s ORDER BY s)
    FROM exploded, LATERAL unnest(synonyms) s
   GROUP BY term;
END;
$$;


ALTER PROCEDURE public.refresh_synonyms() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: jp_city; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.jp_city (
    id integer NOT NULL,
    wkb_geometry bytea,
    n03_001 character varying,
    n03_002 character varying,
    n03_003 character varying,
    n03_004 character varying,
    n03_005 character varying,
    n03_007 character varying,
    full_city_name text
);


ALTER TABLE public.jp_city OWNER TO postgres;

--
-- Name: jp_city_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.jp_city_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.jp_city_id_seq OWNER TO postgres;

--
-- Name: jp_city_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.jp_city_id_seq OWNED BY public.jp_city.id;


--
-- Name: stores; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.stores (
    id bigint NOT NULL,
    lat double precision,
    lon double precision,
    name text,
    operator text,
    pref text,
    city text,
    town text,
    geom public.geometry(Point,4326),
    searchtext text
);


ALTER TABLE public.stores OWNER TO postgres;

--
-- Name: synonym_groups; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.synonym_groups (
    synonyms text[]
);


ALTER TABLE public.synonym_groups OWNER TO postgres;

--
-- Name: synonyms; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.synonyms (
    term text NOT NULL,
    synonyms text[]
);


ALTER TABLE public.synonyms OWNER TO postgres;

--
-- Name: jp_city id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.jp_city ALTER COLUMN id SET DEFAULT nextval('public.jp_city_id_seq'::regclass);


--
-- Name: jp_city jp_city_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.jp_city
    ADD CONSTRAINT jp_city_pkey PRIMARY KEY (id);


--
-- Name: stores stores_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.stores
    ADD CONSTRAINT stores_pkey PRIMARY KEY (id);


--
-- Name: synonyms synonyms_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.synonyms
    ADD CONSTRAINT synonyms_pkey PRIMARY KEY (term);


--
-- Name: idx_city_bigram; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_city_bigram ON public.stores USING pgroonga (city public.pgroonga_text_term_search_ops_v2) WITH (tokenizer='TokenBigram', normalizer='NormalizerAuto');


--
-- Name: idx_pref_bigram; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_pref_bigram ON public.stores USING pgroonga (pref public.pgroonga_text_term_search_ops_v2) WITH (tokenizer='TokenBigram', normalizer='NormalizerAuto');


--
-- Name: idx_stores_pgroonga_full; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_stores_pgroonga_full ON public.stores USING pgroonga (searchtext) WITH (tokenizer='TokenBigram', normalizer='NormalizerAuto');


--
-- Name: idx_syn_group; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_syn_group ON public.synonym_groups USING pgroonga (synonyms public.pgroonga_text_array_term_search_ops_v2);


--
-- Name: idx_syn_term; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_syn_term ON public.synonyms USING pgroonga (term public.pgroonga_text_term_search_ops_v2);


--
-- Name: stores_geom_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX stores_geom_idx ON public.stores USING gist (geom);


--
-- PostgreSQL database dump complete
--

