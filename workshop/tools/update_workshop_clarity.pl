use strict;
use warnings;
use utf8;

my %desc = (
  'workshopitem.main.vdf' => qq{[h1]伤员疗养差事 | Wounded Officer Treatment Assignments[/h1]\n[h2]简体中文[/h2]治疗战役中的永久伤残武将。当前支持四种原版永久伤残：断臂、跛腿、独眼、失明。疗程完成后，会移除对应的永久伤残并添加“伤疤”特性。两项治疗差事：疗伤修养（本地免费，4回合）和寻访名医（4000金，1回合）。\n[h2]English[/h2]This campaign mod treats permanently wounded officers. It supports four vanilla permanent wounds: maimed arm, maimed leg, one-eyed, and blind. Treatment removes the permanent wound and adds the Scarred trait. Assignments: Recuperate (free locally, 4 turns) or Seek Physician (4000 gold, 1 turn).\n[h2]日本語[/h2]キャンペーンで永久負傷した武将を治療します。原版の永久負傷4種類（断腕、負傷脚、隻眼、失明）に対応し、治療完了後は永久負傷を削除して「傷跡」特性に置き換えます。任務は療養（国内無料、4ターン）と名医を探す（4000金、1ターン）です。\n[h2]한국어[/h2]캠페인에서 영구 부상을 입은 장수를 치료합니다. 원본 게임의 영구 부상 4종(팔 절단, 다리 부상, 외눈, 실명)을 지원하며, 치료가 완료되면 영구 부상을 제거하고 ‘흉터’ 특성으로 바꿉니다. 임무는 현지 무료 요양(4턴)과 외국 임무로 파견해 받는 명의 치료(4000금, 1턴)입니다.\n[h2]使用说明 / How to use[/h2]差事由伤员本人执行；疗程完成前召回会取消治疗，已支付费用不退还。主 MOD 内置简体中文；English、日本語、한국어请订阅对应语言包，且语言包依赖本主 MOD：[url=https://steamcommunity.com/sharedfiles/filedetails/?id=3793327818]English[/url] · [url=https://steamcommunity.com/sharedfiles/filedetails/?id=3793327897]日本語[/url] · [url=https://steamcommunity.com/sharedfiles/filedetails/?id=3793328007]한국어[/url]\n[h2]兼容与开源[/h2]适用于《全面战争：三国》1.7.x。GitHub：[url=https://github.com/lmxx1234567/three-kingdoms-wounded-officer-treatment]开源代码[/url] · MIT License},
  'workshopitem.lang-en.vdf' => qq{[h1]English Translation Pack[/h1]\n[h2]What does the mod do?[/h2]This campaign mod treats permanently wounded officers. It currently supports four vanilla permanent wounds: maimed arm, maimed leg, one-eyed, and blind. Once treatment is complete, the permanent wound is removed and replaced with the Scarred trait.\n[h2]Two treatment assignments[/h2][list][*]Recuperate locally: free · 4 turns[*]Seek Physician: 4000 gold · 1 turn[/list]The injured officer performs the assignment. Local recuperation is free; foreign physician treatment requires sending the officer abroad and costs 4000. Recalling the officer cancels treatment, does not refund the fee, and adds no recall delay.\n[h2]Required item[/h2]Subscribe to the [url=https://steamcommunity.com/sharedfiles/filedetails/?id=3793327386]main mod[/url] first, then enable this English translation pack.\n[h2]Other languages and source[/h2][url=https://steamcommunity.com/sharedfiles/filedetails/?id=3793327897]日本語[/url] · [url=https://steamcommunity.com/sharedfiles/filedetails/?id=3793328007]한국어[/url] · [url=https://github.com/lmxx1234567/three-kingdoms-wounded-officer-treatment]GitHub · MIT License[/url]},
  'workshopitem.lang-ja.vdf' => qq{[h1]日本語翻訳パック[/h1]\n[h2]この MOD は何をしますか？[/h2]キャンペーンで永久負傷した武将を治療します。現在、原版の永久負傷4種類（断腕、負傷脚、隻眼、失明）に対応しています。治療完了後、永久負傷を削除して「傷跡」特性に置き換えます。\n[h2]2つの治療任務[/h2][list][*]療養：800金 · 4ターン[*]名医を探す：4000金 · 1ターン[/list]負傷した武将本人が任務を実行します。国内療養は無料、国外の名医による治療は4000金です。途中で呼び戻しても追加の召還待ち時間はありません。\n[h2]必須アイテム[/h2]先に[url=https://steamcommunity.com/sharedfiles/filedetails/?id=3793327386]メイン MOD[/url]を購読し、その後この日本語翻訳パックを有効にしてください。\n[h2]他の言語とソース[/h2][url=https://steamcommunity.com/sharedfiles/filedetails/?id=3793327818]English[/url] · [url=https://steamcommunity.com/sharedfiles/filedetails/?id=3793328007]한국어[/url] · [url=https://github.com/lmxx1234567/three-kingdoms-wounded-officer-treatment]GitHub · MIT License[/url]},
  'workshopitem.lang-ko.vdf' => qq{[h1]한국어 번역팩[/h1]\n[h2]이 모드는 무엇을 하나요?[/h2]캠페인에서 영구 부상을 입은 장수를 치료합니다. 현재 원본 게임의 영구 부상 4종(팔 절단, 다리 부상, 외눈, 실명)을 지원합니다. 치료가 완료되면 영구 부상을 제거하고 ‘흉터’ 특성으로 바꿉니다.\n[h2]치료 임무 2가지[/h2][list][*]현지 요양: 무료 · 4턴[*]명의 찾기: 4000금 · 1턴[/list]부상당한 장수 본인이 임무를 수행합니다. 현지 요양은 무료이며 외국 명의 치료는 4000금입니다. 중간에 소환해도 추가 소환 대기 시간은 없습니다.\n[h2]필수 항목[/h2]먼저[url=https://steamcommunity.com/sharedfiles/filedetails/?id=3793327386]메인 모드[/url]를 구독한 뒤 이 한국어 번역팩을 활성화하세요.\n[h2]다른 언어 및 소스[/h2][url=https://steamcommunity.com/sharedfiles/filedetails/?id=3793327818]English[/url] · [url=https://steamcommunity.com/sharedfiles/filedetails/?id=3793327897]日本語[/url] · [url=https://github.com/lmxx1234567/three-kingdoms-wounded-officer-treatment]GitHub · MIT License[/url]},
);

my $main_usage = qq{[h2]使用说明 / How to use / 使用方法 / 사용 방법[/h2][h3]简体中文[/h3]治疗任务的收益很高，而且治疗完成后永久生效。因此，正在作战或担任官职的武将必须先空闲下来，才能授予治疗任务。疗程至少持续一个季度，完整疗程可能持续一年。传说神医华佗医术高超，即使是夏侯惇这样的武将也有机会被治愈，请谨慎选择治疗对象。<h3>English</h3]Because the benefit is powerful and permanent, the officer must be idle before receiving a treatment assignment. Officers who are fighting or holding an office cannot be assigned. A treatment lasts at least one season, and the full course may take a year. Hua Tuo’s legendary skill means even officers such as Xiahou Dun may be cured—choose your patient carefully.<h3]日本語</h3]治療の効果は非常に大きく、完了後も永久に続きます。そのため、戦闘中または官職に就いている武将は、任務を与える前に空闲にする必要があります。治療期間は少なくとも1季節、完全な治療には1年かかる場合があります。名医・華佗の卓越した技術により、夏侯惇のような武将も治療できる可能性があります。治療対象は慎重に選んでください。<h3]한국어</h3]치료 효과가 매우 크고 치료 후 영구적으로 적용되므로, 치료 임무를 부여하려면 장수가 먼저 한가한 상태여야 합니다. 전투 중이거나 관직을 맡은 장수에게는 임무를 부여할 수 없습니다. 치료 기간은 최소 한 계절이며, 전체 치료 과정은 1년이 걸릴 수도 있습니다. 명의 화타의 뛰어난 의술 덕분에 하후돈 같은 장수도 치료될 가능성이 있으니, 치료 대상을 신중하게 선택하세요.};
$main_usage =~ s{<h3]}{[h3]}g;
$main_usage =~ s{疗程至少持续一个季度，完整疗程可能持续一年。}{普通医生需要一年时间进行修养；如果愿意花费重金聘请华佗这样的名医，则只需一个季度即可完成治疗。};
$main_usage =~ s{A treatment lasts at least one season, and the full course may take a year\.}{Local recuperation is free and takes 4 turns; foreign physician treatment requires sending the officer abroad, costs 4000, and takes 1 turn. Recalling the officer adds no extra delay.};
$main_usage =~ s{治療期間は少なくとも1季節、完全な治療には1年かかる場合があります。}{普通の医師による療養には1年かかりますが、費用をかけて華佗のような名医を雇えば、わずか1季節で治療を完了できます。};
$main_usage =~ s{치료 기간은 최소 한 계절이며, 전체 치료 과정은 1년이 걸릴 수도 있습니다\.}{일반 의사의 치료와 요양에는 1년이 걸리지만, 비용을 들여 화타 같은 명의를 고용하면 단 한 계절 만에 치료를 완료할 수 있습니다.};
$main_usage =~ s{<h3>}{[h3]}g;
$main_usage =~ s{</h3]}{[/h3]}g;
$main_usage =~ s{</h3>}{[/h3]}g;
$main_usage =~ s{任務を与える前に空闲にする必要があります。}{任務を与える前に空けておく必要があります。};

for my $file (keys %desc) {
  my $path = "workshop/vdf/$file";
  open my $in, '<:encoding(UTF-8)', $path or die "$path: $!";
  local $/; my $text = <$in>; close $in;
  my $value = $desc{$file};
  if ($file eq 'workshopitem.main.vdf') {
    $value =~ s{\[h2\]使用说明 / How to use\[/h2\].*?\[h2\]兼容}{${main_usage}[h2]兼容}s;
  }
  $value =~ s/\n//g;
  $text =~ s/("description"\s+)"[^"]*(")/$1 . '"' . $value . $2/se;
  open my $out, '>:encoding(UTF-8)', $path or die "$path: $!";
  print {$out} $text; close $out;
}
