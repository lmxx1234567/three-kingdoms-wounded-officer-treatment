use strict;
use warnings;
use utf8;

my $root = 'workshop/vdf';
my %description = (
  'workshopitem.main.vdf' => qq{[h1]伤员疗养差事 | Wounded Officer Treatment Assignments[/h1]\n\n[h2]简体中文[/h2]\n让永久重伤的武将获得恢复机会。新增两项人物差事：疗伤修养（本地免费，4回合）和寻访名医（4000金，1回合）。疗程完成后，将已配置的永久重伤替换为“伤疤”。本地修养免费4回合，寻访名医必须将人物派往外国差事并支付4000金，仅需1回合，召回无额外回合开销。适用于《全面战争：三国》1.7.x。\n\n[h2]English[/h2]\nThis campaign mod gives permanently wounded officers a chance to recover. It adds Recuperate (free locally, 4 turns) and Seek Physician (4000 gold, 1 turn). Completed treatment replaces configured severe wounds with the Scarred trait.\n\n[h2]日本語[/h2]\n永久負傷した武将を治療できるキャンペーン任務を追加します。療養（国内無料・4ターン）と名医を探す（4000金・1ターン）を利用できます。\n\n[h2]한국어[/h2]\n영구 부상을 입은 장수를 치료할 수 있는 캠페인 임무를 추가합니다. 현지 무료 요양(4턴)과 외국 명의 치료(4000금·1턴)를 이용할 수 있습니다.\n\n[h2]语言包 / Translation Packs[/h2]\n[url=https://steamcommunity.com/sharedfiles/filedetails/?id=3793327818]English[/url] · [url=https://steamcommunity.com/sharedfiles/filedetails/?id=3793327897]日本語[/url] · [url=https://steamcommunity.com/sharedfiles/filedetails/?id=3793328007]한국어[/url]\n\n[h2]开源 / Open Source[/h2]\nGitHub: https://github.com/lmxx1234567/three-kingdoms-wounded-officer-treatment\nMIT License. 首次使用前请备份存档。},
  'workshopitem.lang-en.vdf' => qq{[h1]English Translation Pack[/h1]\n\nThis is the English translation for Wounded Officer Treatment Assignments. Subscribe to the main mod first, then enable this pack after it. Do not enable multiple translation packs at the same time.\n\nMain mod: https://steamcommunity.com/sharedfiles/filedetails/?id=3793327386\n\nThe mod adds two campaign character assignments: Recuperate (free locally, 4 turns) and Seek Physician (4000 gold, 1 turn).\n\nOther languages: [url=https://steamcommunity.com/sharedfiles/filedetails/?id=3793327897]日本語[/url] · [url=https://steamcommunity.com/sharedfiles/filedetails/?id=3793328007]한국어[/url]\n\nOpen source under the MIT License: https://github.com/lmxx1234567/three-kingdoms-wounded-officer-treatment},
  'workshopitem.lang-ja.vdf' => qq{[h1]日本語翻訳パック[/h1]\n\nWounded Officer Treatment Assignments の日本語翻訳パックです。先にメイン MOD を購読し、その後この翻訳パックを有効にしてください。複数の翻訳パックを同時に有効にしないでください。\n\nメイン MOD： https://steamcommunity.com/sharedfiles/filedetails/?id=3793327386\n\nこの MOD は、療養（国内無料・4ターン）と名医を探す（4000金・1ターン）の2つのキャンペーン任務を追加します。\n\n他の言語： [url=https://steamcommunity.com/sharedfiles/filedetails/?id=3793327818]English[/url] · [url=https://steamcommunity.com/sharedfiles/filedetails/?id=3793328007]한국어[/url]\n\nMIT License で公開されているオープンソースです： https://github.com/lmxx1234567/three-kingdoms-wounded-officer-treatment},
  'workshopitem.lang-ko.vdf' => qq{[h1]한국어 번역팩[/h1]\n\nWounded Officer Treatment Assignments 한국어 번역 팩입니다. 먼저 메인 모드를 구독한 뒤 이 번역 팩을 활성화하세요. 여러 번역 팩을 동시에 활성화하지 마세요.\n\n메인 모드: https://steamcommunity.com/sharedfiles/filedetails/?id=3793327386\n\n이 모드는 현지 무료 요양(4턴)과 외국 명의 치료(4000금·1턴), 두 가지 캠페인 임무를 추가합니다.\n\n다른 언어: [url=https://steamcommunity.com/sharedfiles/filedetails/?id=3793327818]English[/url] · [url=https://steamcommunity.com/sharedfiles/filedetails/?id=3793327897]日本語[/url]\n\nMIT License 오픈 소스: https://github.com/lmxx1234567/three-kingdoms-wounded-officer-treatment},
);

for my $file (keys %description) {
  my $path = "$root/$file";
  open my $in, '<:encoding(UTF-8)', $path or die "$path: $!";
  local $/;
  my $text = <$in>;
  close $in;
  my $value = $description{$file};
  $value =~ s/\n//g;
  $text =~ s/("description"\s+)"[^"]*(")/$1 . '"' . $value . $2/se;
  open my $out, '>:encoding(UTF-8)', $path or die "$path: $!";
  print {$out} $text;
  close $out;
}
