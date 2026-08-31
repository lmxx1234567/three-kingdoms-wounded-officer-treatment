use strict;
use warnings;
use utf8;

my %desc = (
  'workshopitem.lang-en.vdf' => qq{[h1]English Translation Pack[/h1]\n[h2]About this pack[/h2]English translation for Wounded Officer Treatment Assignments. Subscribe to the [url=https://steamcommunity.com/sharedfiles/filedetails/?id=3793327386]main mod[/url] first, then enable this translation pack. Do not enable multiple translation packs at the same time.\n[h2]What the mod adds[/h2][list][*]Recuperate — 800 gold · 4 turns[*]Seek Physician — 4000 gold · 1 turn[/list]\n[h2]Other languages[/h2][url=https://steamcommunity.com/sharedfiles/filedetails/?id=3793327897]日本語[/url] · [url=https://steamcommunity.com/sharedfiles/filedetails/?id=3793328007]한국어[/url]\n[h2]Open source[/h2]MIT License · [url=https://github.com/lmxx1234567/three-kingdoms-wounded-officer-treatment]GitHub source[/url]},
  'workshopitem.lang-ja.vdf' => qq{[h1]日本語翻訳パック[/h1]\n[h2]このパックについて[/h2]Wounded Officer Treatment Assignments の日本語翻訳パックです。先に[url=https://steamcommunity.com/sharedfiles/filedetails/?id=3793327386]メイン MOD[/url]を購読し、その後この翻訳パックを有効にしてください。複数の翻訳パックを同時に有効にしないでください。\n[h2]追加される任務[/h2][list][*]療養 — 800金 · 4ターン[*]名医を探す — 4000金 · 1ターン[/list]\n[h2]他の言語[/h2][url=https://steamcommunity.com/sharedfiles/filedetails/?id=3793327818]English[/url] · [url=https://steamcommunity.com/sharedfiles/filedetails/?id=3793328007]한국어[/url]\n[h2]オープンソース[/h2]MIT License · [url=https://github.com/lmxx1234567/three-kingdoms-wounded-officer-treatment]GitHub ソース[/url]},
  'workshopitem.lang-ko.vdf' => qq{[h1]한국어 번역팩[/h1]\n[h2]이 번역팩에 대하여[/h2]Wounded Officer Treatment Assignments 한국어 번역 팩입니다. 먼저[url=https://steamcommunity.com/sharedfiles/filedetails/?id=3793327386]메인 모드[/url]를 구독한 뒤 이 번역 팩을 활성화하세요. 여러 번역 팩을 동시에 활성화하지 마세요.\n[h2]추가되는 임무[/h2][list][*]요양 — 800금 · 4턴[*]명의 찾기 — 4000금 · 1턴[/list]\n[h2]다른 언어[/h2][url=https://steamcommunity.com/sharedfiles/filedetails/?id=3793327818]English[/url] · [url=https://steamcommunity.com/sharedfiles/filedetails/?id=3793327897]日本語[/url]\n[h2]오픈 소스[/h2]MIT License · [url=https://github.com/lmxx1234567/three-kingdoms-wounded-officer-treatment]GitHub 소스[/url]},
);

for my $file (keys %desc) {
  my $path = "workshop/vdf/$file";
  open my $in, '<:encoding(UTF-8)', $path or die "$path: $!";
  local $/; my $text = <$in>; close $in;
  my $value = $desc{$file}; $value =~ s/\n//g;
  $text =~ s/("description"\s+)"[^"]*(")/$1 . '"' . $value . $2/se;
  open my $out, '>:encoding(UTF-8)', $path or die "$path: $!";
  print {$out} $text; close $out;
}
