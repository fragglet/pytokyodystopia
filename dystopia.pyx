#
# Copyright (c) 2010, Simon Howard
# 
# Permission to use, copy, modify, and/or distribute this software
# for any purpose with or without fee is hereby granted, provided
# that the above copyright notice and this permission notice appear
# in all copies.
# 
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL
# WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE
# AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR
# CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
# LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT,
# NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN
# CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
# 
# NOTE: The license above only applies to the code in this wrapper.
# Tokyo Dystopia is licensed under the GNU LGPL; see the file
# COPYING for more details.
#

cdef extern from "stdint.h":
	ctypedef signed long int64_t
	ctypedef unsigned long uint64_t
	ctypedef signed int int32_t
	ctypedef unsigned int uint32_t
	ctypedef signed short int16_t
	ctypedef unsigned short uint16_t
	ctypedef signed char int8_t
	ctypedef unsigned char uint8_t

# ----------------------------------------------------------------------
#
#  tcutil.h (utility functions)
#
# ----------------------------------------------------------------------

cdef extern from "tcutil.h":
	ctypedef struct TCLIST:
		pass

	TCLIST *tclistnew2(int anum)
	void tclistdel(TCLIST *list)
	void tclistpush2(TCLIST *list, char *str)
	int tclistnum(TCLIST *list)
	char *tclistval2(TCLIST *list, int index)

# Convert a list of Python strings to a TCLIST.

cdef TCLIST *list_to_tclist(list):
	cdef TCLIST *result

	result = tclistnew2(len(list))

	for x in list:
		tclistpush2(result, x)
	
	return result

# TCLIST to a list of Python strings ...

cdef tclist_to_list(TCLIST *tclist):
	result = []

	for i in range(tclistnum(tclist)):
		result.append(tclistval2(tclist, i))

	return result

# Helper function. Given a pointer to an array of result ID values,
# generate a Python list containing them.

cdef result_list(uint64_t *result, unsigned int result_len):
	pyresult = []

	for i in range(result_len):
		pyresult.append(result[i])

	return pyresult

# ----------------------------------------------------------------------
#
#  Core API:
#
# ----------------------------------------------------------------------

cdef extern from "dystopia.h":
	enum idb_open_mode:
		IDBOREADER,
		IDBOWRITER,
		IDBOCREAT,
		IDBOTRUNC,
		IDBONOLCK,
		IDBOLCKNB

	enum idb_search_mode:
		IDBSSUBSTR,
		IDBSPREFIX,
		IDBSSUFFIX,
		IDBSFULL,
		IDBSTOKEN,
		IDBSTOKPRE,
		IDBSTOKSUF

	enum idb_tune_mode:
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

cdef class IDB:
	""" Tokyo Dystopia indexed database object. """

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

	def __setitem__(self, id, text):
		""" Store a new record in the database.

		    `id' specifies the ID number of the record.  It should
		    be positive.
		    `text' specifies the string of the record.
		"""

		if not tcidbput(self.db, id, text):
			self.__throw_exception()

	def __delitem__(self, id):
		""" Remove a record from the database.

		    `id' specifies the ID number of the record to remove.
		"""

		if not tcidbout(self.db, id):
			self.__throw_exception()

	def __getitem__(self, id):
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

	def clear(self):
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

# ----------------------------------------------------------------------
#
#  Q-Gram API
#
# ----------------------------------------------------------------------

cdef extern from "tcqdb.h":
	ctypedef struct TCMAP:
		pass

	ctypedef struct TCQDB:
		pass

	ctypedef struct QDBRSET:
		uint64_t *ids
		int num

	ctypedef struct TCIDSET:
		uint64_t *buckets
		uint32_t bnum
		TCMAP *trails

	enum qdb_tune_mode:
		QDBTLARGE,
		QDBTDEFLATE,
		QDBTBZIP,
		QDBTTCBS

	enum qdb_open_mode:
		QDBOREADER,
		QDBOWRITER,
		QDBOCREAT,
		QDBOTRUNC,
		QDBONOLCK,
		QDBOLCKNB

	enum qdb_search_mode:
		QDBSSUBSTR,
		QDBSPREFIX,
		QDBSSUFFIX,
		QDBSFULL

	char *tcqdberrmsg(int ecode)
	TCQDB *tcqdbnew()
	void tcqdbdel(TCQDB *qdb)
	int tcqdbecode(TCQDB *qdb)
	bint tcqdbopen(TCQDB *qdb, char *path, int omode)
	bint tcqdbclose(TCQDB *qdb)
	bint tcqdbput(TCQDB *qdb, int64_t id, char *text)
	bint tcqdbout(TCQDB *qdb, int64_t id, char *text)
	uint64_t *tcqdbsearch(TCQDB *qdb, char *word, int smode, int *np)
	bint tcqdbtune(TCQDB *qdb, int64_t etnum, uint8_t opts)
	bint tcqdbsetcache(TCQDB *qdb, int64_t icsiz, int32_t lcnum)
	bint tcqdbsetfwmmax(TCQDB *qdb, uint32_t fwmmax)
	bint tcqdbsync(TCQDB *qdb)
	bint tcqdboptimize(TCQDB *qdb)
	bint tcqdbvanish(TCQDB *qdb)
	bint tcqdbcopy(TCQDB *qdb, char *path)
	char *tcqdbpath(TCQDB *qdb)
	uint64_t tcqdbtnum(TCQDB *qdb)
	uint64_t tcqdbfsiz(TCQDB *qdb)
	bint tcqdbmemsync(TCQDB *qdb, int level)
	bint tcqdbcacheclear(TCQDB *qdb)
	uint64_t tcqdbinode(TCQDB *qdb)
	uint64_t tcqdbmtime(TCQDB *qdb)
	uint8_t tcqdbopts(TCQDB *qdb)
	uint32_t tcqdbfwmmax(TCQDB *qdb)
	uint32_t tcqdbcnum(TCQDB *qdb)

	# TODO?

	#void tcqdbsetsynccb(TCQDB *qdb, bint (*cb)(int, int, char *, void *), void *opq)
	uint64_t *tcqdbresunion(QDBRSET *rsets, int rsnum, int *np)
	uint64_t *tcqdbresisect(QDBRSET *rsets, int rsnum, int *np)
	uint64_t *tcqdbresdiff(QDBRSET *rsets, int rsnum, int *np)
	void tctextnormalize(char *text, int opts)
	TCIDSET *tcidsetnew(uint32_t bnum)
	void tcidsetdel(TCIDSET *idset)
	void tcidsetmark(TCIDSET *idset, int64_t id)
	bint tcidsetcheck(TCIDSET *idset, int64_t id)
	void tcidsetclear(TCIDSET *idset)

cdef class QDB:
	TLARGE, = QDBTLARGE,
	TDEFLATE, = QDBTDEFLATE,
	TBZIP, = QDBTBZIP,
	TTCBS = QDBTTCBS

	OREADER, = QDBOREADER,
	OWRITER, = QDBOWRITER,
	OCREAT, = QDBOCREAT,
	OTRUNC, = QDBOTRUNC,
	ONOLCK, = QDBONOLCK,
	OLCKNB = QDBOLCKNB

	SSUBSTR, = QDBSSUBSTR,
	SPREFIX, = QDBSPREFIX,
	SSUFFIX, = QDBSSUFFIX,
	SFULL = QDBSFULL

	cdef TCQDB *db

	cdef __throw_exception(self):
		errcode = tcqdbecode(self.db)
		errmsg = tcqdberrmsg(errcode)
		raise Exception(errmsg)

	def __init__(self):
		self.db = tcqdbnew()

	def __del__(self):
		tcqdbdel(self.db)

	def __len__(self):
		return tcqdbtnum(self.db)

	def open(self, path, omode):
		if not tcqdbopen(self.db, path, omode):
			self.__throw_exception()

	def close(self):
		if not tcqdbclose(self.db):
			self.__throw_exception()

	def path(self):
		cdef char *result
		result = tcqdbpath(self.db)

		if result == NULL:
			return None
		else:
			return result

	def copy(self, path):
		if not tcqdbcopy(self.db, path):
			self.__throw_exception()

	def put(self, id, text):
		if not tcqdbput(self.db, id, text):
			self.__throw_exception()

	def out(self, id, text):
		if not tcqdbout(self.db, id, text):
			self.__throw_exception()

	def search(self, word, smode):
		cdef int result_len
		cdef uint64_t *result

		result = tcqdbsearch(self.db, word, smode, &result_len)

		if result == NULL:
			self.__throw_exception()

		return result_list(result, result_len)

	def tune(self, etnum, opts):
		if not tcqdbtune(self.db, etnum, opts):
			self.__throw_exception()

	def setcache(self, icsiz, lcnum):
		if not tcqdbsetcache(self.db, icsiz, lcnum):
			self.__throw_exception()

	def setfwmmax(self, fwmmax):
		if not tcqdbsetfwmmax(self.db, fwmmax):
			self.__throw_exception()

	def sync(self):
		if not tcqdbsync(self.db):
			self.__throw_exception()

	def optimize(self):
		if not tcqdboptimize(self.db):
			self.__throw_exception()

	def clear(self):
		if not tcqdbvanish(self.db):
			self.__throw_exception()

	def fsiz(self):
		return tcqdbfsiz(self.db)

	def memsync(self, level):
		if not tcqdbmemsync(self.db, level):
			self.__throw_exception()

	def cacheclear(self):
		if not tcqdbcacheclear(self.db):
			self.__throw_exception()

	def inode(self):
		return tcqdbinode(self.db)

	def mtime(self):
		return tcqdbmtime(self.db)

	def opts(self):
		return tcqdbopts(self.db)

	def fwmmax(self):
		return tcqdbfwmmax(self.db)

	def cnum(self):
		return tcqdbcnum(self.db)

# ----------------------------------------------------------------------
#
#  Simple API:
#
# ----------------------------------------------------------------------

cdef extern from "laputa.h":
	ctypedef struct TCJDB:
		pass

	enum jdb_tune_mode:
		JDBTLARGE,
		JDBTDEFLATE,
		JDBTBZIP,
		JDBTTCBS

	enum jdb_open_mode:
		JDBOREADER,
		JDBOWRITER,
		JDBOCREAT,
		JDBOTRUNC,
		JDBONOLCK,
		JDBOLCKNB

	enum jdb_search_mode:
		JDBSSUBSTR,
		JDBSPREFIX,
		JDBSSUFFIX,
		JDBSFULL

	char *tcjdberrmsg(int ecode)
	TCJDB *tcjdbnew()
	void tcjdbdel(TCJDB *jdb)
	int tcjdbecode(TCJDB *jdb)
	bint tcjdbopen(TCJDB *jdb, char *path, int omode)
	bint tcjdbclose(TCJDB *jdb)
	bint tcjdbsync(TCJDB *jdb)
	bint tcjdboptimize(TCJDB *jdb)
	bint tcjdbvanish(TCJDB *jdb)
	uint64_t tcjdbrnum(TCJDB *jdb)
	uint64_t tcjdbfsiz(TCJDB *jdb)
	char *tcjdbpath(TCJDB *jdb)
	bint tcjdbcopy(TCJDB *jdb, char *path)
	bint tcjdbtune(TCJDB *jdb, int64_t ernum, int64_t etnum, int64_t iusiz, uint8_t opts)
	bint tcjdbsetcache(TCJDB *jdb, int64_t icsiz, int32_t lcnum)
	bint tcjdbsetfwmmax(TCJDB *jdb, uint32_t fwmmax)
	bint tcjdbput2(TCJDB *jdb, int64_t id, char *text, char *delims)
	char *tcjdbget2(TCJDB *jdb, int64_t id)
	bint tcjdbmemsync(TCJDB *jdb, int level)
	uint64_t tcjdbinode(TCJDB *jdb)
	uint32_t tcjdbmtime(TCJDB *jdb)
	uint8_t tcjdbopts(TCJDB *jdb)
	void tcjdbsetexopts(TCJDB *jdb, uint32_t exopts)
	uint64_t *tcjdbsearch(TCJDB *jdb, char *word, int smode, int *np)
	uint64_t *tcjdbsearch2(TCJDB *jdb, char *expr, int *np)
	bint tcjdbiterinit(TCJDB *jdb)
	uint64_t tcjdbiternext(TCJDB *jdb)
	bint tcjdbout(TCJDB *jdb, int64_t id)
	bint tcjdbput(TCJDB *jdb, int64_t id, TCLIST *words)
	TCLIST *tcjdbget(TCJDB *jdb, int64_t id)

	void tcjdbsetdbgfd(TCJDB *jdb, int fd)
	int tcjdbdbgfd(TCJDB *jdb)
	#void tcjdbsetsynccb(TCJDB *jdb, bint (*cb)(int, int, char *, void *), void *opq)

cdef class JDB:
	TLARGE = JDBTLARGE
	TDEFLATE = JDBTDEFLATE
	TBZIP = JDBTBZIP
	TTCBS = JDBTTCBS

	OREADER = JDBOREADER
	OWRITER = JDBOWRITER
	OCREAT = JDBOCREAT
	OTRUNC = JDBOTRUNC
	ONOLCK = JDBONOLCK
	OLCKNB = JDBOLCKNB

	SSUBSTR = JDBSSUBSTR
	SPREFIX = JDBSPREFIX
	SSUFFIX = JDBSSUFFIX
	SFULL = JDBSFULL

	cdef TCJDB *db

	cdef __throw_exception(self):
		errcode = tcjdbecode(self.db)
		errmsg = tcjdberrmsg(errcode)
		raise Exception(errmsg)

	def __init__(self):
		self.db = tcjdbnew()

	def __delitem__(self, id):
		if not tcjdbout(self.db, id):
			self.__throw_exception()

	def __getitem__(self, id):
		cdef TCLIST *words
		words = tcjdbget(self.db, id)

		if words == NULL:
			return None
		else:
			result = tclist_to_list(words)
			tclistdel(words)
			return result

	def __setitem__(self, id, list):
		cdef TCLIST *words
		words = list_to_tclist(list)

		success = tcjdbput(self.db, id, words)

		tclistdel(words)

		if not success:
			self.__throw_exception()

	def __del__(self):
		tcjdbdel(self.db)

	def __len__(self):
		return tcjdbrnum(self.db)

	def __iter__(self):

		if not tcjdbiterinit(self.db):
			self.__throw_exception()

		# The API only allows for one iterator at a time;
		# the iterator reference is to the DB object.
		# This is rather un-Python-like.

		return self

	# This method is here because the database object acts as its
	# own iterator.

	def __next__(self):

		val = tcjdbiternext(self.db)

		if val == 0:
			raise StopIteration()

		return val

	def open(self, path, omode):
		if not tcjdbopen(self.db, path, omode):
			self.__throw_exception()

	def close(self):
		if not tcjdbclose(self.db):
			self.__throw_exception()

	def path(self):
		return tcjdbpath(self.db)

	def copy(self, path):
		if not tcjdbcopy(self.db, path):
			self.__throw_exception()

	def sync(self):
		if not tcjdbsync(self.db):
			self.__throw_exception()

	def optimize(self):
		if not tcjdboptimize(self.db):
			self.__throw_exception()

	def clear(self):
		if not tcjdbvanish(self.db):
			self.__throw_exception()

	def fsiz(self):
		return tcjdbfsiz(self.db)

	def tune(self, ernum, etnum, iusiz, opts):
		if not tcjdbtune(self.db, ernum, etnum, iusiz, opts):
			self.__throw_exception()

	def setcache(self, icsiz, lcnum):
		if not tcjdbsetcache(self.db, icsiz, lcnum):
			self.__throw_exception()

	def setfwmmax(self, fwmmax):
		if not tcjdbsetfwmmax(self.db, fwmmax):
			self.__throw_exception()

	def put2(self, id, text, delims):
		if not tcjdbput2(self.db, id, text, delims):
			self.__throw_exception()

	def get2(self, id):
		return tcjdbget2(self.db, id)

	def search(self, word, smode):

		cdef int result_len
		cdef uint64_t *result

		result = tcjdbsearch(self.db, word, smode, &result_len)

		if result == NULL:
			self.__throw_exception()

		return result_list(result, result_len)

	def search2(self, expression):

		cdef int result_len
		cdef uint64_t *result

		result = tcjdbsearch2(self.db, expression, &result_len)

		if result == NULL:
			self.__throw_exception()

		return result_list(result, result_len)

	def memsync(self, level):
		if not tcjdbmemsync(self.db, level):
			self.__throw_exception()

	def inode(self):
		return tcjdbinode(self.db)

	def mtime(self):
		return tcjdbmtime(self.db)

	def opts(self):
		return tcjdbopts(self.db)

	def setexopts(self, exopts):
		tcjdbsetexopts(self.db, exopts)

