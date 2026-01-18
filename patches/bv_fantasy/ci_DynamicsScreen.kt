package dev.aaa1115910.bv.tv.screens.main.home

import android.content.Intent
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.grid.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.*
import androidx.compose.ui.input.key.*
import androidx.compose.ui.unit.dp
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.ui.Alignment
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.dimensionResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.sp
import coil.compose.AsyncImage
import dev.aaa1115910.biliapi.entity.user.DynamicVideo
import dev.aaa1115910.bv.tv.component.LoadingTip
import dev.aaa1115910.bv.entity.carddata.VideoCardData
import dev.aaa1115910.bv.tv.R
import dev.aaa1115910.bv.tv.activities.user.FollowActivity
import dev.aaa1115910.bv.tv.activities.video.UpInfoActivity
import dev.aaa1115910.bv.tv.activities.video.VideoInfoActivity
import dev.aaa1115910.bv.tv.component.videocard.SmallVideoCard
import dev.aaa1115910.bv.tv.util.ProvideListBringIntoViewSpec
import dev.aaa1115910.bv.viewmodel.home.DynamicViewModel
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import org.koin.androidx.compose.koinViewModel

@Composable
fun DynamicsScreen(
    modifier: Modifier = Modifier,
    lazyGridState: LazyGridState = rememberLazyGridState(),
    dynamicViewModel: DynamicViewModel = koinViewModel()
) {
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    var currentFocusedIndex by remember { mutableIntStateOf(-1) }
    val shouldLoadMore by remember {
        derivedStateOf { dynamicViewModel.dynamicVideoList.isNotEmpty() && currentFocusedIndex + 12 > dynamicViewModel.dynamicVideoList.size }
    }
    val showTip by remember {
        derivedStateOf { dynamicViewModel.dynamicVideoList.isNotEmpty() && currentFocusedIndex >= 0 }
    }

    val onClickVideo: (DynamicVideo) -> Unit = { dynamic ->
        VideoInfoActivity.actionStart(
            context = context,
            aid = dynamic.aid,
            proxyArea = ProxyArea.checkProxyArea(dynamic.title)
        )
    }

    val onLongClickVideo: (DynamicVideo) -> Unit = { dynamic ->
        UpInfoActivity.actionStart(
            context,
            mid = dynamic.authorId,
            name = dynamic.author,
            face = dynamic.authorFace
        )
    }

    LaunchedEffect(shouldLoadMore) {
        if (shouldLoadMore) {
            scope.launch(Dispatchers.IO) {
                dynamicViewModel.loadMoreVideo()
            }
        }
    }

    // 1. 为每个卡片预生成 FocusRequester
    val requesters = remember { mutableStateMapOf<Int, FocusRequester>() }

    if (dynamicViewModel.isLogin) {
        val padding = dimensionResource(R.dimen.grid_padding)
        val spacedBy = dimensionResource(R.dimen.grid_spacedBy)
        if (showTip) {
            Text(
                modifier = Modifier.fillMaxWidth().offset(x = (-20).dp, y = (-8).dp),
                text = stringResource(R.string.entry_follow_screen),
                color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.5f),
                fontSize = 12.sp,
                textAlign = TextAlign.End
            )
        }
        ProvideListBringIntoViewSpec {
            LazyVerticalGrid(
                modifier = modifier
                    .fillMaxSize()
                    .onFocusChanged {
                        if (!it.isFocused) currentFocusedIndex = -1
                    }
                    .onPreviewKeyEvent {
                        if (it.type == KeyEventType.KeyUp && it.key == Key.Menu) {
                            context.startActivity(Intent(context, FollowActivity::class.java))
                            return@onPreviewKeyEvent true
                        }
                        false
                    },
                columns = GridCells.Fixed(4),
                state = lazyGridState,
                contentPadding = PaddingValues(padding),
                verticalArrangement = Arrangement.spacedBy(spacedBy),
                horizontalArrangement = Arrangement.spacedBy(spacedBy)
            ) {
                itemsIndexed(dynamicViewModel.dynamicVideoList) { index, item ->
                    val focusRequester = requesters.getOrPut(index) { FocusRequester() }
                    SmallVideoCard(
                        data = remember(item.aid) {
                            VideoCardData(
                                avid = item.aid,
                                title = item.title,
                                cover = item.cover,
                                play = item.play,
                                danmaku = item.danmaku,
                                upName = item.author,
                                time = item.duration * 1000L,
                                pubTime = item.pubTime,
                                isChargingArc = item.isChargingArc,
                                badgeText = item.chargingArcBadge
                            )
                        },
                        onClick = { onClickVideo(item) },
                        onLongClick = { onLongClickVideo(item) },
                        onFocus = { currentFocusedIndex = index },
                        modifier = Modifier
                            // 2. 绑定焦点节点
                            .focusRequester(focusRequester)
                            // 3. 横向/纵向焦点锁定
                            .focusProperties {
                                val row = index / 4
                                val col = index % 4
                                right = if (col == 3) FocusRequester.Default
                                        else requesters.getOrElse(index + 1) { FocusRequester.Default }
                                left  = if (col == 0) FocusRequester.Default
                                        else requesters.getOrElse(index - 1) { FocusRequester.Default }
                                down  = if (index + 4 < dynamicViewModel.dynamicVideoList.size) requesters[index + 4]
                                        else FocusRequester.Default
                                up    = if (index - 4 >= 0) requesters[index - 4]
                                        else FocusRequester.Default
                            }
                            // 4. 长按 DOWN 且最后一行可见时吃掉事件
                            .onKeyEvent { keyEvent ->
                                val nav = keyEvent.nativeKeyEvent
                                if (nav.action == KeyEvent.ACTION_DOWN
                                    && nav.repeatCount > 0
                                    && nav.keyCode == KeyEvent.KEYCODE_DPAD_DOWN
                                    && lazyGridState.layoutInfo.visibleItemsInfo.lastOrNull()?.index == dynamicViewModel.dynamicVideoList.lastIndex
                                ) {
                                    true
                                } else {
                                    false
                                }
                            }
                    )
                }

                if (dynamicViewModel.loadingVideo) {
                    item(span = { GridItemSpan(maxLineSpan) }) {
                        Box(
                            modifier = Modifier.fillMaxSize(),
                            contentAlignment = Alignment.Center
                        ) {
                            LoadingTip()
                        }
                    }
                }

                if (!dynamicViewModel.videoHasMore) {
                    item(span = { GridItemSpan(maxLineSpan) }) {
                        Text(
                            text = "没有更多了捏",
                            color = Color.White
                        )
                    }
                }
            }
        }
    } else {
        Box(
            modifier = Modifier.fillMaxSize(),
            contentAlignment = Alignment.Center
        ) {
            Text(text = "请先登录")
        }
    }
}