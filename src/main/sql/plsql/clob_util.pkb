--
-- Copyright 2014-2015 Victor Osolovskiy, Sergey Navrotskiy
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
--

create or replace package body clob_util as


function create_temporary(in_content in varchar2 := '') return clob
is
  l_clob clob;
begin
  dbms_lob.createtemporary(l_clob, true);
  if in_content is not null then
    put(l_clob, in_content);
  end if;
  return l_clob;
end create_temporary;


procedure put(
  io_clob in out nocopy clob,
  in_string in varchar2,
  in_indent in naturaln := 0
)
is
  l_indented_string varchar2(32767) := rpad(' ', in_indent, ' ') || in_string;
begin
  if l_indented_string is not null then
    dbms_lob.writeappend(io_clob, length(l_indented_string), l_indented_string);
  end if;
end put;


procedure put_line(
  io_clob in out nocopy clob,
  in_string in varchar2 := '',
  in_indent in naturaln := 0
)
is
begin
  put(io_clob, in_string || chr(10), in_indent);
end put_line;


procedure append(
  io_clob in out nocopy clob,
  in_text in clob,
  in_indent in naturaln := 0
)
is
  l_space varchar2(32767);
begin
  if in_indent > 0 then
    l_space := rpad(' ', in_indent, ' ');
    put(io_clob, l_space);
    dbms_lob.append(io_clob, replace(in_text, chr(10), chr(10) || l_space));
  else
    dbms_lob.append(io_clob, in_text);
  end if;
end append;


function trim_spaces(in_clob in clob) return clob
is
begin
  return regexp_replace(in_clob, '^[[:space:]]+|[[:space:]]+$');
end trim_spaces;


function join(
  in_clobs in clob_nt,
  in_delim in varchar2 := '',
  in_final_delim in boolean := false,
  in_refine_spaces in boolean := false
) return clob
is
  l_i pls_integer := in_clobs.first();
  l_i_next pls_integer;
  l_tmp clob;
  l_res clob := create_temporary();
begin
  while l_i is not null loop
    l_i_next := in_clobs.next(l_i);
    if in_refine_spaces then
      l_tmp := trim_spaces(in_clobs(l_i));
      if dbms_lob.getlength(l_tmp) > 0 then
        append(l_res, l_tmp);
        if in_final_delim or l_i_next is not null then
          put(
            l_res,
            chr(10) || in_delim ||
            case when l_i_next is not null then chr(10) end
          );
        end if;
      end if;
    else
      append(l_res, in_clobs(l_i));
      if in_final_delim or l_i_next is not null then
        put(l_res, in_delim);
      end if;
    end if;
    l_i := l_i_next;
  end loop;
  return l_res;
end join;


function split_into_lines(in_clob in clob) return dbms_sql.varchar2a
is
  l_length pls_integer := dbms_lob.getlength(in_clob);
  l_start_pos pls_integer;
  l_eol_pos pls_integer;
  l_lines dbms_sql.varchar2a;
  l_no pls_integer := 1;
begin
  l_start_pos := 1;
  loop
    l_eol_pos := dbms_lob.instr(in_clob, chr(10), l_start_pos);

    l_lines(l_no) :=
      dbms_lob.substr(
        in_clob,
        case
          when l_eol_pos > 0 then l_eol_pos - l_start_pos
          else l_length - l_start_pos + 1
        end,
        l_start_pos
      );

    exit when l_eol_pos = 0 or l_eol_pos = l_length;

    l_start_pos := l_eol_pos + 1;
    l_no := l_no + 1;
  end loop;

  return l_lines;
end split_into_lines;


function split_into_pieces(
  in_clob in clob,
  in_delim in varchar2,
  in_trim_spaces in boolean := false
) return clob_nt
is
  l_length pls_integer := dbms_lob.getlength(in_clob);
  l_start_pos pls_integer := 1;
  l_end_pos pls_integer;
  l_tmp clob;
  l_res clob_nt := clob_nt();
begin
  if in_clob is null or l_length = 0 then
    return l_res;
  end if;

  loop
    l_end_pos := dbms_lob.instr(in_clob, in_delim, l_start_pos);

    if nvl(l_end_pos, 0) = 0 then
      l_end_pos := l_length + 1;
    end if;

    if l_start_pos < l_end_pos then
      l_tmp := create_temporary();
      dbms_lob.copy(l_tmp, in_clob, l_end_pos - l_start_pos, 1, l_start_pos);
      if in_trim_spaces then
        l_tmp := trim_spaces(l_tmp);
      end if;
      if dbms_lob.getlength(l_tmp) > 0 then
        l_res.extend();
        l_res(l_res.last()) := l_tmp;
      end if;
    end if;

    exit when l_end_pos > l_length;

    l_start_pos := l_end_pos + length(in_delim);
    exit when l_start_pos >= l_length;
  end loop;

  return l_res;
end split_into_pieces;


/**
 * Prints the given lines to DBMS_OUTPUT with the ending character.
 *
 * @param  in_lines  the lines to be printed
 * @param  in_eof    the ending character (optional)
 */
procedure show(in_lines in dbms_sql.varchar2a, in_eof in varchar2 := '')
is
begin
  for i in 1..in_lines.count() loop
    dbms_output.put_line(in_lines(i));
  end loop;

  if in_eof is not null then
    dbms_output.put_line(in_eof);
  end if;
end show;


procedure show(in_clob in clob, in_eof in varchar2 := '')
is
begin
  show(split_into_lines(in_clob), in_eof);
end show;


procedure exec(in_clob in clob, in_echo in boolean := false)
is
  l_lines dbms_sql.varchar2a;
  $if dbms_db_version.version < 11 $then
    l_clob_is_large boolean := false;
    l_str varchar2(32767);
    l_cur integer;
    l_res integer;
  $end
begin
  -- By default the CLOB is executed via Native Dynamic SQL, but if its size
  -- exceeds 32767 bytes and the Oracle version is less then 11g, the CLOB is
  -- executed via DBMS_SQL.
  $if dbms_db_version.version < 11 $then
    -- Try to put the CLOB into a varchar2 variable. If it doesn't fit,
    -- to_char() raises the VALUE_ERROR exception.
    begin
      l_str := to_char(in_clob);
    exception
      when value_error then
        l_clob_is_large := true;
    end;
  $end

  -- Split the CLOB into lines only in case of printing or executing via
  -- DBMS_SQL
  if in_echo $if dbms_db_version.version < 11 $then or l_clob_is_large $end then
    l_lines := split_into_lines(in_clob);
  end if;

  if in_echo then
    show(l_lines, '/');
  end if;

  $if dbms_db_version.version < 11 $then
    if l_clob_is_large then
      begin
        l_cur := dbms_sql.open_cursor();
        dbms_sql.parse(
          l_cur, l_lines, 1, l_lines.count(), true, dbms_sql.native
        );
        l_res := dbms_sql.execute(l_cur);
        dbms_sql.close_cursor(l_cur);
      exception
        when others then
          if dbms_sql.is_open(l_cur) then
            dbms_sql.close_cursor(l_cur);
          end if;
          raise;
      end;
    else
      execute immediate l_str;
    end if;
  $else
    execute immediate in_clob;
  $end
end exec;


end clob_util;
/
