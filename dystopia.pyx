
cdef extern from "stdint.h":
	ctypedef signed long int64_t
	ctypedef unsigned long uint64_t
	ctypedef signed int int32_t
	ctypedef unsigned int uint32_t
	ctypedef signed short int16_t
	ctypedef unsigned short uint16_t
	ctypedef signed char int8_t
	ctypedef unsigned char uint8_t

# Simple API:

cdef extern from "dystopia.h":
	enum open_mode:
		IDBOREADER,
		IDBOWRITER,
		IDBOCREAT,
		IDBOTRUNC,
		IDBONOLCK,
		IDBOLCKNB

	enum search_mode:
		IDBSSUBSTR,
		IDBSPREFIX,
		IDBSSUFFIX,
		IDBSFULL,
		IDBSTOKEN,
		IDBSTOKPRE,
		IDBSTOKSUF

	enum tune_mode:
		IDBTLARGE,
		IDBTDEFLATE,
		IDBTBZIP,
		IDBTTCBS

	ctypedef struct TCIDB:
		pass

	char *tcidberrmsg(int ecode)

	TCIDB *tcidbnew()
	void tcidbdel(TCIDB *idb)
	int tcidbecode(TCIDB *idb)
	bint tcidbtune(TCIDB *idb, int64_t ernum, int64_t etnum, int64_t iusiz, uint8_t opts)
	bint tcidbsetcache(TCIDB *idb, int64_t icsiz, int32_t lcnum)
	bint tcidbsetfwmmax(TCIDB *idb, uint32_t fwmmax)
	bint tcidbopen(TCIDB *idb, char *path, int omode)
	bint tcidbclose(TCIDB *idb)
	bint tcidbput(TCIDB *idb, int64_t id, char *text)
	bint tcidbout(TCIDB *idb, int64_t id)
	char *tcidbget(TCIDB *idb, int64_t id)
	uint64_t *tcidbsearch(TCIDB *idb, char *word, int smode, int *np)
	uint64_t *tcidbsearch2(TCIDB *idb, char *expr, int *np)
	bint tcidbiterinit(TCIDB *idb)
	uint64_t tcidbiternext(TCIDB *idb)
	bint tcidbsync(TCIDB *idb)
	bint tcidboptimize(TCIDB *idb)
	bint tcidbvanish(TCIDB *idb)
	bint tcidbcopy(TCIDB *idb, char *path)
	char *tcidbpath(TCIDB *idb)
	uint64_t tcidbrnum(TCIDB *idb)
	uint64_t tcidbfsiz(TCIDB *idb)

# ----------------------------------------------------------------------
#
#  Simple API
#
# ----------------------------------------------------------------------

# Open flags

OREADER = IDBOREADER
OWRITER = IDBOWRITER
OCREAT = IDBOCREAT
OTRUNC = IDBOTRUNC
ONOLCK = IDBONOLCK
OLCKNB = IDBOLCKNB

# Search flags

SSUBSTR = IDBSSUBSTR
SPREFIX = IDBSPREFIX
SSUFFIX = IDBSSUFFIX
SFULL = IDBSFULL
STOKEN = IDBSTOKEN
STOKPRE = IDBSTOKPRE
STOKSUF = IDBSTOKSUF

# Tuning flags

TLARGE = IDBTLARGE
TDEFLATE = IDBTDEFLATE
TBZIP = IDBTBZIP
TTCBS = IDBTTCBS

# Helper function. Given a pointer to an array of result ID values,
# generate a Python list containing them.

cdef result_list(uint64_t *result, unsigned int result_len):
	pyresult = []

	for i in range(result_len):
		pyresult.append(result[i])

	return pyresult

cdef class IDB:
	""" Tokyo Dystopia indexed database object. """

	cdef TCIDB *db

	cdef __throw_exception(self):
		errcode = tcidbecode(self.db)
		errmsg = tcidberrmsg(errcode)
		raise Exception(errmsg)

	def __init__(self):
		""" Constructor for new indexed database object. """

		self.db = tcidbnew()

	def __del__(self):
		""" Destructor for indexed database object. """

		tcidbdel(self.db)

	def __len__(self):
		""" Get the number of records in the database. """

		return tcidbrnum(self.db)

	def __iter__(self):
		""" Iterate over all records in the database. """

		if not tcidbiterinit(self.db):
			self.__throw_exception()

		# The API only allows for one iterator at a time;
		# the iterator reference is to the DB object.
		# This is rather un-Python-like.

		return self

	# This method is here because the database object acts as its
	# own iterator.

	def __next__(self):
		""" Get the ID number of the next record in the database. """

		val = tcidbiternext(self.db)

		if val == 0:
			raise StopIteration()

		return val

	def open(self, path, mode):
		""" Open an indexed database on disk.

		    `path' specifies the path of the database directory.
		    `omode' specifies the connection mode: `OWRITER' as
		    a writer, `OREADER' as a reader. If the mode is
		    `OWRITER', the following may be added by bitwise-or:
		    `OCREAT', to create a new database if it does not
		    exist, `OTRUNC', to create a new database regardless
		    of whether one exists. `OREADER' and `OWRITER' can
		    be added to by bitwise-or: `ONOLCK', to open the
		    database directory without file locking, or `OLCKNB',
		    to perform locking without blocking. """

		if not tcidbopen(self.db, path, mode):
			self.__throw_exception()

	def close(self):
		""" Close the indexed database on disk. """

		if not tcidbclose(self.db):
			self.__throw_exception()

	def path(self):
		""" Get the path to the database on disk. """

		cdef char *result
		result = tcidbpath(self.db)

		if result == NULL:
			return None
		else:
			return result

	def fsiz(self):
		""" Get the size of teh database files on disk. """

		return tcidbfsiz(self.db)

	def put(self, id, text):
		""" Store a new record in the database.

		    `id' specifies the ID number of the record.  It should
		    be positive.
		    `text' specifies the string of the record.
		"""

		if not tcidbput(self.db, id, text):
			self.__throw_exception()

	def out(self, id):
		""" Remove a record from the database.

		    `id' specifies the ID number of the record to remove.
		"""

		if not tcidbout(self.db, id):
			self.__throw_exception()

	def get(self, id):
		""" Get the string data associated with the specified
		    database record.

		    `id' specifies the ID number of the record to retrieve.
		"""

		cdef char *text
		text = tcidbget(self.db, id)

		if text == NULL:
			return None
		else:
			return text

	def vanish(self):
		""" Remove all records from the database. """

		if not tcidbvanish(self.db):
			self.__throw_exception()

	def search(self, word, smode):
		""" Search for records in the database, and return a
		    list of IDs of records that match the search string.

		    `word' specifies the search string.
		    `smode' specifies the matching mode: `SSUBSTR' for
		    substring matching, `SPREFIX' for prefix matching,
		    `SSUFFIX' for suffix matching, `SFULL' for full matching,
		    `STOKEN' for token matching, `STOKPRE' for token prefix
		    matching, or `STOKSUF' as token suffix matching.
		"""

		cdef int result_len
		cdef uint64_t *result

		result = tcidbsearch(self.db, word, smode, &result_len)

		if result == NULL:
			self.__throw_exception()

		return result_list(result, result_len)

	def search2(self, expression):
		""" Search the database for a compound expression, and
		    return a list of IDs of records that match the
		    search string.

		    `expression' specifies the expression to search for.
		"""

		cdef int result_len
		cdef uint64_t *result

		result = tcidbsearch2(self.db, expression, &result_len)

		if result == NULL:
			self.__throw_exception()

		return result_list(result, result_len)


	def tune(self, ernum, etnum, iusiz, opts):
		""" Set the tuning parameters of the database.

		    `ernum' specifies the expected number of records
		    to be stored. If it is not more than 0, the
		    default value is specified. The default value is
		    1000000.
		    `etnum' specifies the expected number of tokens to
		    be stored. If it is not more than 0, the default
		    value is specified. The default value is 1000000.
		    `iusiz' specifies the unit size of each index
		    file. If it is not more than 0, the default value
		    is specified. The default value is 536870912.
		    `opts' specifies options by bitwise-or: `TLARGE'
		    specifies that the size of the database can be
		    larger than 2GB by using 64-bit bucket array,
		    `TDEFLATE' specifies that each page is compressed
		    with Deflate encoding, `TBZIP' specifies that each
		    page is compressed with BZIP2 encoding, `TTCBS'
		    specifies that each page is compressed with TCBS
		    encoding.
		"""

		if not tcidbtune(self.db, ernum, etnum, iusiz, opts):
			self.__throw_exception()

	def setcache(self, icsiz, lcnum):
		""" Set the caching parameters of the database.

		    `icsiz' specifies the capacity size of the token
		    cache. If it is not more than 0, the default value
		    is specified. The default value is 134217728.
		    `lcnum' specifies the maximum number of cached
		    leaf nodes of B+ tree.  If it is not more than 0,
		    the default value is specified. The default value
		    is 64 for writer or 1024 for reader.
		"""

		if not tcidbsetcache(self.db, icsiz, lcnum):
			self.__throw_exception()

	def setfwmmax(self, fwmmax):
		""" Set the maximum number of forward matching expansions
		    in the database. """

		if not tcidbsetfwmmax(self.db, fwmmax):
			self.__throw_exception()

	def sync(self):
		""" Synchronize updated contents of the database with
		    the files and the device. """

		if not tcidbsync(self.db):
			self.__throw_exception()

	def optimize(self):
		""" Optimize the database files on disk. """

		if not tcidboptimize(self.db):
			self.__throw_exception()

