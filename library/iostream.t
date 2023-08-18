! T3X module: I/O streams
! Nils M Holm, 1997,1998,2000,2002,2019,2022
! Public Domain / 0BSD License

module iostreams;

 public struct IOSTREAM = IOS_FD, IOS_BUF, IOS_LEN, IOS_PTR, IOS_LIM, IOS_FLAGS;

 public const	FREAD	= 0x0001,	! read-only
		FWRITE	= 0x0002,	! write-only
		FRDWR	= FREAD|FWRITE,	! read/write
		FKILLCR	= 0x0004,	! remove CRs from input
		FADDCR	= 0x0008,	! add CR before LF in output
		FTRANS	= FKILLCR|FADDCR;

 const		FEOF	= 0x0100,	! EOF detected
		FLASTW	= 0x0200;	! last access was of type 'write'

 ! seek modes
 public const	SEEK_SET = T3X.SEEK_SET,	! from beginning
		SEEK_FWD = T3X.SEEK_FWD,	! relative/forward
		SEEK_END = T3X.SEEK_END,	! from end (backward)
		SEEK_BCK = T3X.SEEK_BCK;	! relative/backward

 iosreset(ios) do
	ios[IOS_PTR] := 0;
	ios[IOS_LIM] := 0;
 end

 public create(ios, fd, bufp, len, mode) do
	ios[IOS_FD] := fd;
	ios[IOS_BUF] := bufp;
	ios[IOS_FLAGS] := mode;
	ios[IOS_LEN] := len;
	iosreset(ios);
	return ios;
 end

 public open(ios, name, fl) do var fd, mode, ifl;
	ifl := fl & FRDWR;
	mode := ifl = FREAD-> T3X.OREAD:
		ifl = FWRITE-> T3X.OWRITE:
		ifl = FREAD|FWRITE-> T3X.ORDWR: %1;
	if (mode < 0) return %1;
	fd := t3x.open(name, mode);
	if (fd < 0) return %1;
	ios[IOS_FD] := fd;
	iosreset(ios);
	return ios;
 end

 public flush(ios) do var k;
	if (ios[IOS_FLAGS] & (FWRITE|FLASTW) = FWRITE|FLASTW /\ ios[IOS_PTR])
	do
		k := t3x.write(ios[IOS_FD], ios[IOS_BUF], ios[IOS_LEN]);
		if (k \= ios[IOS_PTR]) return %1;
	end
	iosreset(ios);
 end

 public close(ios) do
	if (flush(ios) = %1) return %1;
	t3x.close(ios[IOS_FD]);
	ios[IOS_FLAGS] := 0;
 end

 written(ios) ios[IOS_FLAGS] := ios[IOS_FLAGS] |  FLASTW;
 readd(ios)   ios[IOS_FLAGS] := ios[IOS_FLAGS] & ~FLASTW;

 public wrch(ios, ch) do
	written(ios);
	if (ios[IOS_FLAGS] & FADDCR /\ ch = '\n') wrch(ios, '\r');
	if (ios[IOS_PTR] >= ios[IOS_LEN] /\ flush(ios) = %1) return %1;
	ios[IOS_BUF]::ios[IOS_PTR] := ch;
	ios[IOS_PTR] := ios[IOS_PTR]+1;
	return ch;
 end

 public write(ios, buf, len) do var i;
	written(ios);
	i := 0;
	while (i < len) do
		if (ios[IOS_PTR] >= ios[IOS_LEN] /\ flush(ios) = %1) return %1;
		if (ios[IOS_FLAGS] & FADDCR) do
			if (buf::i = '\n') do
				ios[IOS_BUF]::ios[IOS_PTR] := '\r';
				ios[IOS_PTR] := ios[IOS_PTR]+1;
				if (	ios[IOS_PTR] >= ios[IOS_LEN] /\
					flush(ios) = %1
				)
					return %1;
			end
		end
		ios[IOS_BUF]::ios[IOS_PTR] := buf::i;
		ios[IOS_PTR] := ios[IOS_PTR]+1;
		i := i+1;
	end
	return i;
 end

 public writes(ios, str) do var k;
	k := t3x.memscan(str, 0, 32767);
	if (k .> 32766) return %1;
	return write(ios, str, k);
 end

 more(ios) do var k;
	if (ios[IOS_FLAGS] & FREAD) do
		k := t3x.read(ios[IOS_FD], ios[IOS_BUF], ios[IOS_LEN]);
		if (k <= 0) do
			ios[IOS_FLAGS] := ios[IOS_FLAGS] | FEOF;
			if (k < 0) return %1;
		end
		ios[IOS_PTR] := 0;
		ios[IOS_LIM] := k;
		return k;
	end
 end

 public rdch(ios) do var c;
	readd(ios);
	while (1) do
		if (ios[IOS_FLAGS] & FEOF) return %1;
		if (ios[IOS_PTR] >= ios[IOS_LIM] /\ more(ios) < 1) return %1;
		c := ios[IOS_BUF]::ios[IOS_PTR];
		ios[IOS_PTR] := ios[IOS_PTR]+1;
		ie (ios[IOS_FLAGS] & FKILLCR)
			if (c \= '\r') leave;
		else
			leave;
	end
	return c;
 end

 doread(ios, buf, len, ckln) do var i;
	readd(ios);
	i := 0;
	while (i < len) do
		if (ios[IOS_PTR] >= ios[IOS_LIM] /\ more(ios) < 1) leave;
		ie (ios[IOS_FLAGS] & FKILLCR) do
			if (ios[IOS_BUF]::ios[IOS_PTR] \= '\r') do
				buf::i := ios[IOS_BUF]::ios[IOS_PTR];
				i := i+1;
			end
		end
		else do
			buf::i := ios[IOS_BUF]::ios[IOS_PTR];
			i := i+1;
		end
		ios[IOS_PTR] := ios[IOS_PTR]+1;
		if (ckln /\ buf::(i-1) = '\n') leave;
	end
	if (ckln) buf::i := 0;
	return i;
 end

 public read(ios, buf, len) return doread(ios, buf, len, 0);

 public reads(ios, buf, len) return doread(ios, buf, len, 1);

! public move(ios, off, how) do var delta;
!	ie (ios[IOS_FLAGS] & FLASTW) do
!		if (flush(ios) = %1) return %1;
!	end
!	else ie (how = SEEK_FWD) do
!		delta := ios[IOS_LIM] - ios[IOS_PTR];
!		if (flush(ios) = %1) return %1;
!		off := off - delta;
!	end
!	else ie (how = SEEK_BCK) do
!		delta := ios[IOS_LIM] - ios[IOS_PTR];
!		if (flush(ios) = %1) return %1;
!		off := off + delta;
!	end
!	else do
!		if (flush(ios) = %1) return %1;
!	end
!	return t3x.seek(ios[IOS_FD], off, how);
! end

 public eof(ios) return (ios[IOS_FLAGS] & FEOF) \= 0;

 public reset(ios) ios[IOS_FLAGS] := ios[IOS_FLAGS] & ~FEOF;

end
